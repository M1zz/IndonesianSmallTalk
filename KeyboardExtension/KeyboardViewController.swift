import UIKit

/// "사노라면" 표현 키보드 — 한국어 뜻을 보고 탭하면 인도네시아어가 입력된다.
class KeyboardViewController: UIInputViewController {

    enum Filter: Int { case all, positive, negative, slang }

    /// 표현 또는 슬랭 — 같은 셀에서 통합 렌더링
    enum Item {
        case phrase(MyPhrase)
        case slang(SlangPair)

        var korean: String {
            switch self {
            case .phrase(let p): return p.korean
            case .slang(let s): return s.korean
            }
        }
        var indonesian: String {
            switch self {
            case .phrase(let p): return p.indonesian
            case .slang(let s): return s.indonesian
            }
        }
        var sub: String? {
            switch self {
            case .phrase: return nil
            case .slang(let s): return s.note
            }
        }
        var polarity: Polarity {
            switch self {
            case .phrase(let p): return p.polarity
            case .slang: return .neutral
            }
        }
        var isSlang: Bool {
            if case .slang = self { return true }
            return false
        }
    }

    private var items: [Item] = []
    private var filtered: [Item] = []
    private var currentFilter: Filter = .all
    private var direction: InputDirection = .kor2ind
    private var directionButton: UIButton!

    private var collectionView: UICollectionView!
    private let topBar = UIStackView()
    private let bottomBar = UIStackView()
    private let emptyLabel = UILabel()
    private var nextKeyboardButton: UIButton!
    private var backspaceButton: UIButton!

    // 길게 눌러 백스페이스 반복용
    private var backspaceTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        direction = KeyboardSettings.inputDirection
        if directionButton != nil {
            styleDirectionButton(directionButton)
        }
        loadPhrases()
    }

    override func textWillChange(_ textInput: UITextInput?) {}
    override func textDidChange(_ textInput: UITextInput?) {
        let proxy = textDocumentProxy
        let isDark = (proxy.keyboardAppearance == .dark)
        applyAppearance(dark: isDark)
    }

    // MARK: - UI

    private func setupViews() {
        view.backgroundColor = UIColor(white: 0.96, alpha: 1)

        // 상단 필터 바
        topBar.axis = .horizontal
        topBar.alignment = .center
        topBar.distribution = .fill
        topBar.spacing = 8
        topBar.translatesAutoresizingMaskIntoConstraints = false
        topBar.layoutMargins = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        topBar.isLayoutMarginsRelativeArrangement = true

        directionButton = makeDirectionButton()

        let filterStack = UIStackView()
        filterStack.axis = .horizontal
        filterStack.spacing = 6
        filterStack.distribution = .fill
        filterStack.alignment = .center
        filterStack.addArrangedSubview(makeFilterButton(title: "전체", filter: .all))
        filterStack.addArrangedSubview(makeFilterButton(title: "긍정", filter: .positive))
        filterStack.addArrangedSubview(makeFilterButton(title: "부정", filter: .negative))
        filterStack.addArrangedSubview(makeFilterButton(title: "슬랭", filter: .slang))

        topBar.addArrangedSubview(directionButton)
        topBar.addArrangedSubview(UIView())
        topBar.addArrangedSubview(filterStack)
        view.addSubview(topBar)

        // 표현 그리드 (Flow Layout, 자동 크기)
        let layout = UICollectionViewFlowLayout()
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.minimumInteritemSpacing = 6
        layout.minimumLineSpacing = 6
        layout.sectionInset = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(ChipCell.self, forCellWithReuseIdentifier: "chip")
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        collectionView.contentInsetAdjustmentBehavior = .never
        view.addSubview(collectionView)

        // 빈 상태 라벨
        emptyLabel.text = "메인 앱에서 표현을 먼저 저장해주세요"
        emptyLabel.font = .systemFont(ofSize: 12)
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.isHidden = true
        view.addSubview(emptyLabel)

        // 하단 바 (다음 키보드 + 백스페이스)
        bottomBar.axis = .horizontal
        bottomBar.alignment = .center
        bottomBar.distribution = .fill
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.layoutMargins = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        bottomBar.isLayoutMarginsRelativeArrangement = true

        nextKeyboardButton = makeBarButton(systemName: "globe")
        nextKeyboardButton.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)

        backspaceButton = makeBarButton(systemName: "delete.left")
        backspaceButton.addTarget(self, action: #selector(didTapBackspace), for: .touchUpInside)
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressBackspace(_:)))
        longPress.minimumPressDuration = 0.4
        backspaceButton.addGestureRecognizer(longPress)

        bottomBar.addArrangedSubview(nextKeyboardButton)
        bottomBar.addArrangedSubview(UIView())
        bottomBar.addArrangedSubview(backspaceButton)
        view.addSubview(bottomBar)

        NSLayoutConstraint.activate([
            topBar.topAnchor.constraint(equalTo: view.topAnchor),
            topBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBar.heightAnchor.constraint(equalToConstant: 44),

            collectionView.topAnchor.constraint(equalTo: topBar.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 48),
        ])

        // 키보드 전체 높이 (선택). 너무 길면 host app 컨텐츠가 가려짐
        view.heightAnchor.constraint(equalToConstant: 290).isActive = true
    }

    private func makeFilterButton(title: String, filter: Filter) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .medium
        config.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 11, bottom: 5, trailing: 11)
        config.title = title
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = .systemFont(ofSize: 11, weight: .semibold)
            return out
        }
        let b = UIButton(configuration: config)
        b.tag = filter.rawValue
        b.addTarget(self, action: #selector(didTapFilter(_:)), for: .touchUpInside)
        b.setContentHuggingPriority(.required, for: .horizontal)
        b.setContentCompressionResistancePriority(.required, for: .horizontal)
        styleFilterButton(b, selected: filter == currentFilter)
        return b
    }

    private func styleFilterButton(_ b: UIButton, selected: Bool) {
        guard var config = b.configuration else { return }
        let filter = Filter(rawValue: b.tag) ?? .all
        let color = ChipPalette.filterColor(filter)
        if selected {
            config.baseBackgroundColor = color
            config.baseForegroundColor = .white
            config.background.strokeColor = .clear
            config.background.strokeWidth = 0
        } else {
            // 비선택 — 옅은 카테고리 컬러로 미리보기
            config.baseBackgroundColor = color.withAlphaComponent(0.14)
            config.baseForegroundColor = color
            config.background.strokeColor = color.withAlphaComponent(0.35)
            config.background.strokeWidth = 0.7
        }
        b.configuration = config
    }

    private func makeDirectionButton() -> UIButton {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .medium
        config.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 9, bottom: 5, trailing: 9)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = .systemFont(ofSize: 11, weight: .bold)
            return out
        }
        config.image = UIImage(systemName: "arrow.left.arrow.right",
                               withConfiguration: UIImage.SymbolConfiguration(pointSize: 9, weight: .bold))
        config.imagePadding = 4
        let b = UIButton(configuration: config)
        b.setContentHuggingPriority(.required, for: .horizontal)
        b.setContentCompressionResistancePriority(.required, for: .horizontal)
        b.addTarget(self, action: #selector(didTapDirection), for: .touchUpInside)
        styleDirectionButton(b)
        return b
    }

    private func styleDirectionButton(_ b: UIButton) {
        guard var config = b.configuration else { return }
        config.title = direction.symbol
        config.baseBackgroundColor = UIColor(white: 1, alpha: 0.85)
        config.baseForegroundColor = .label
        config.background.strokeColor = .separator
        config.background.strokeWidth = 0.5
        b.configuration = config
    }

    @objc private func didTapDirection() {
        direction = direction.toggled
        KeyboardSettings.inputDirection = direction
        styleDirectionButton(directionButton)
        collectionView.reloadData()
    }

    private func makeBarButton(systemName: String) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: systemName,
                               withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .medium))
        config.cornerStyle = .medium
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        config.baseBackgroundColor = UIColor(white: 1, alpha: 0.85)
        config.baseForegroundColor = .label
        let b = UIButton(configuration: config)
        b.setContentHuggingPriority(.required, for: .horizontal)
        b.setContentCompressionResistancePriority(.required, for: .horizontal)
        return b
    }

    private func applyAppearance(dark: Bool) {
        view.backgroundColor = dark ? UIColor(white: 0.12, alpha: 1) : UIColor(white: 0.96, alpha: 1)
        collectionView.reloadData()
    }

    // MARK: - Data

    private func loadPhrases() {
        let phrases = SharedPhraseReader.loadPhrases()
        let phraseItems: [Item] = phrases.map { .phrase($0) }
        let slangItems: [Item] = KeyboardSettings.slangEnabled
            ? SharedSlangReader.loadAll().map { .slang($0) }
            : []
        items = phraseItems + slangItems

        applyFilter()
    }

    private func applyFilter() {
        switch currentFilter {
        case .all:
            filtered = items
        case .positive:
            filtered = items.filter { $0.polarity == .positive }
        case .negative:
            filtered = items.filter { $0.polarity == .negative }
        case .slang:
            filtered = items.filter { $0.isSlang }
        }
        emptyLabel.isHidden = !filtered.isEmpty
        emptyLabel.text = items.isEmpty
            ? "메인 앱에서 표현을 먼저 저장해주세요"
            : "이 분류에 해당하는 항목이 없어요"
        collectionView.reloadData()
    }

    // MARK: - Actions

    @objc private func didTapFilter(_ sender: UIButton) {
        guard let filter = Filter(rawValue: sender.tag) else { return }
        currentFilter = filter
        applyFilter()
        // 모든 필터 버튼 스타일 갱신
        if let stack = sender.superview as? UIStackView {
            for case let b as UIButton in stack.arrangedSubviews {
                styleFilterButton(b, selected: b.tag == filter.rawValue)
            }
        }
    }

    @objc private func didTapBackspace() {
        textDocumentProxy.deleteBackward()
    }

    @objc private func didLongPressBackspace(_ gr: UILongPressGestureRecognizer) {
        switch gr.state {
        case .began:
            backspaceTimer?.invalidate()
            backspaceTimer = Timer.scheduledTimer(withTimeInterval: 0.07, repeats: true) { [weak self] _ in
                self?.textDocumentProxy.deleteBackward()
            }
        case .ended, .cancelled, .failed:
            backspaceTimer?.invalidate()
            backspaceTimer = nil
        default:
            break
        }
    }
}

// MARK: - Table

extension KeyboardViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        filtered.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "chip", for: indexPath) as! ChipCell
        cell.configure(with: filtered[indexPath.item], direction: direction)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = filtered[indexPath.item]
        let textToInsert: String
        switch direction {
        case .kor2ind: textToInsert = item.indonesian
        case .ind2kor: textToInsert = item.korean
        }
        textDocumentProxy.insertText(textToInsert)
        // 짧은 시각 피드백
        if let cell = collectionView.cellForItem(at: indexPath) {
            UIView.animate(withDuration: 0.12, animations: {
                cell.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
            }) { _ in
                UIView.animate(withDuration: 0.12) {
                    cell.transform = .identity
                }
            }
        }
    }
}

// MARK: - Color palette by category

enum ChipPalette {
    /// 카테고리별 대표 색.
    static let slang     = UIColor.systemPink
    static let positive  = UIColor.systemGreen
    static let negative  = UIColor.systemOrange
    static let neutral   = UIColor.systemBlue

    static func colors(for item: KeyboardViewController.Item) -> (bg: UIColor, fg: UIColor, secondary: UIColor) {
        if item.isSlang {
            return (slang.withAlphaComponent(0.15),
                    slang,
                    slang.withAlphaComponent(0.7))
        }
        switch item.polarity {
        case .positive:
            return (positive.withAlphaComponent(0.18),
                    UIColor(red: 0.0, green: 0.45, blue: 0.20, alpha: 1),
                    positive.withAlphaComponent(0.85))
        case .negative:
            return (negative.withAlphaComponent(0.18),
                    UIColor(red: 0.65, green: 0.30, blue: 0.0, alpha: 1),
                    negative.withAlphaComponent(0.85))
        case .neutral:
            return (neutral.withAlphaComponent(0.12),
                    neutral,
                    neutral.withAlphaComponent(0.7))
        }
    }

    static func filterColor(_ filter: KeyboardViewController.Filter) -> UIColor {
        switch filter {
        case .all:      return neutral
        case .positive: return positive
        case .negative: return negative
        case .slang:    return slang
        }
    }
}

// MARK: - Chip cell (그리드)

final class ChipCell: UICollectionViewCell {
    static let maxWidth: CGFloat = 220

    private let primaryLabel = UILabel()
    private let secondaryLabel = UILabel()
    private let backgroundFill = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundFill.translatesAutoresizingMaskIntoConstraints = false
        backgroundFill.layer.cornerRadius = 12
        backgroundFill.layer.borderWidth = 1
        backgroundFill.layer.masksToBounds = true
        contentView.addSubview(backgroundFill)

        primaryLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        primaryLabel.numberOfLines = 1
        primaryLabel.lineBreakMode = .byTruncatingTail
        primaryLabel.translatesAutoresizingMaskIntoConstraints = false

        secondaryLabel.font = .systemFont(ofSize: 10.5)
        secondaryLabel.numberOfLines = 1
        secondaryLabel.lineBreakMode = .byTruncatingTail
        secondaryLabel.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [primaryLabel, secondaryLabel])
        stack.axis = .vertical
        stack.spacing = 1
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            backgroundFill.topAnchor.constraint(equalTo: contentView.topAnchor),
            backgroundFill.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            backgroundFill.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            backgroundFill.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with item: KeyboardViewController.Item, direction: InputDirection) {
        let primary: String
        let secondary: String
        switch direction {
        case .kor2ind:
            primary = item.korean.isEmpty ? "(번역 없음)" : item.korean
            secondary = item.indonesian
        case .ind2kor:
            primary = item.indonesian
            secondary = item.korean.isEmpty ? "(번역 없음)" : item.korean
        }
        primaryLabel.text = primary
        if let sub = item.sub, !sub.isEmpty {
            secondaryLabel.text = "\(secondary) · \(sub)"
        } else {
            secondaryLabel.text = secondary
        }

        let palette = ChipPalette.colors(for: item)
        backgroundFill.backgroundColor = palette.bg
        backgroundFill.layer.borderColor = palette.fg.withAlphaComponent(0.35).cgColor
        primaryLabel.textColor = palette.fg
        secondaryLabel.textColor = palette.secondary
    }

    /// estimatedItemSize + automaticSize 와 함께 동작 — 폭 제한
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attr = super.preferredLayoutAttributesFitting(layoutAttributes)
        // 너무 길면 잘라내서 한 줄에 여러개 들어가게
        if attr.frame.width > Self.maxWidth {
            attr.frame.size.width = Self.maxWidth
        }
        return attr
    }
}
