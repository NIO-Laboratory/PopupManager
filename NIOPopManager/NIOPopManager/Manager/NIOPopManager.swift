import Foundation


/**
 MaskType
 1. Black mask
 黑色蒙版
 2. White mask
 白色蒙版
 3. Pure white
 纯白色
 4. Pure transparent
 透明
 5. Black translucent
 黑色透明
 */
public enum NIOPopupMaskType {
   case nioPopupMaskTypeBlackBlur
   case nioPopupMaskTypeWhiteBlur
   case nioPopupMaskTypeWhite
   case nioPopupMaskTypeClear
   case nioPopupMaskTypeBlackTranslucent //default
}


/**
 NIOPopupControlTouchType
 1. nioTouchMaskView: The effect on the mask view
 触碰方法作用在在蒙版View上面
 2. nioTouchContentView: The effect on the content view
 触碰方法作用在在内容View上面
 */
public enum NIOPopupControlTouchType {
    case nioTouchMaskView
    case nioTouchContentView
}


/**
 NIOPopManager control popup view popup and other actions
 NIOPopManager 管理 PopupView 弹出 消失 等操作
 */
public class NIOPopManager<T: NIOPopupViewProtocol> : NSObject, UIGestureRecognizerDelegate {
    
    //MARK: - Propertys
    
    /// ContentView
    /// 内容View
    public var contentView: T
    
    /// Find window view by frontWindow function
    /// 找到Window层
    public var superView: UIView?
    
    /// NIOPopManager contentView isAutoDismiss, default is ture
    /// ContentView 是否自动 Dismiss
    public var isAutoDismiss: Bool = false
    
    /// NIOPopManager contentView auto dismiss default value 3.0
    /// 自动消失的时间
    public var autoDismissDuration: TimeInterval = 3.0
    
    /// MaskView on window view
    /// 蒙层 View
    public var maskView: UIView? {
        didSet {
            guard maskView != nil else { return }
            //添加蒙层
            addBlurView(maskType: maskType, targetView: maskView)
            //生效指定的蒙层
            effectMaskViewBlur(maskView: maskView!)
        }
    }
    
    
    /// MaskView Dismiss Callback Block
    /// parameter               回调参数:
    /// maskview type           1.点击MaskView
    /// contentview type        2.点击ContentView
    public var dimissOfMaskViewBlock: ((NIOPopupControlTouchType) -> Void)? = nil
    
    public var maskType: NIOPopupMaskType
    
    /// Mask view alpha default 0.5
    /// 蒙版透明度 默认0.5
    public var maskAlpha: CGFloat = 0.5
    
    
    //MARK: - initialize
    public init(maskType: NIOPopupMaskType = .nioPopupMaskTypeBlackBlur,
                contentView: T,
                superView: UIView? = nil) {
        self.maskType = maskType
        self.maskView = nil
        self.superView = superView
        self.contentView = contentView
        super.init()
        setSuperView()
        setMaskView()
    }
    
    @discardableResult
    public func show() -> UIView? {
        
        if contentView.isShowMaskView { //Show MaskView 蒙层
            guard let mask = maskView,
                let sv = superView else { return nil }
            if !mask.subviews.contains(contentView) {
                mask.addSubview(contentView)
            }
            if !sv.subviews.contains(mask) {
                sv.addSubview(mask)
            }
            contentView.beginAnimation {}
            autoDismiss()
            
            return mask
        }
        else {
            guard let sv = superView else { return nil }

            if !sv.subviews.contains(contentView) {
                sv.addSubview(contentView)
            }
            contentView.beginAnimation {}
            autoDismiss()
            
            return maskView
        }
        
    }
    
    public func dismiss(completion: ((Bool) -> Void)? = nil) {
        if let dismissBlock = self.dimissOfMaskViewBlock { dismissBlock(.nioTouchContentView) }
        dismissMaskView(completion)
    }
    
    
    //MARK: - Private
    
    private func setSuperView() {
        if let sv = superView {
            self.superView = sv
        }
        else {
            self.superView = frontWindow()
        }
    }
    
    private func setMaskView() {
        maskView = UIView(frame: superView?.bounds ?? .zero)
        maskviewAddTapGesture()
    }
    
    private func maskviewAddTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(maskViewTapGesture))
        tapGesture.numberOfTapsRequired = 1
        tapGesture.delegate = self
        maskView?.addGestureRecognizer(tapGesture)
    }
    
    @objc private func maskViewTapGesture() {
        if let dismissBlock = self.dimissOfMaskViewBlock { dismissBlock(.nioTouchMaskView) }
        dismissMaskView()
    }
    
    private func dismissMaskView(_ completion: ((Bool) -> Void)? = nil) {
        contentView.endAnimation { [weak self] in
            self?.maskView?.removeFromSuperview()
            self?.contentView.removeFromSuperview()
            if let cmp = completion { cmp(true) }
        }
    }
    
    private func addBlurView(maskType: NIOPopupMaskType,
                             targetView: UIView?) {
        if [NIOPopupMaskType.nioPopupMaskTypeBlackBlur, NIOPopupMaskType.nioPopupMaskTypeWhiteBlur].contains(maskType) {
            let visualEffectView = UIVisualEffectView()
            visualEffectView.effect = UIBlurEffect(style: .light)
            visualEffectView.frame = superView?.bounds ?? .zero
            
            if !(targetView?.subviews.first is UIVisualEffectView) {
                targetView?.insertSubview(visualEffectView, at: 0)
            }
        }
    }
    
    private func effectMaskViewBlur(maskView: UIView) {
        switch maskType {
        case .nioPopupMaskTypeBlackTranslucent:
            maskView.backgroundColor = UIColor(white: 0.0, alpha: maskAlpha)
            break
        case .nioPopupMaskTypeBlackBlur:
            let effectView = maskView.subviews.first as? UIVisualEffectView
            effectView?.effect = UIBlurEffect(style: .dark)
            break
        case .nioPopupMaskTypeClear:
            maskView.backgroundColor = .clear
            break
        case .nioPopupMaskTypeWhite:
            maskView.backgroundColor = .white
            break
        case .nioPopupMaskTypeWhiteBlur:
            let effectView = maskView.subviews.first as? UIVisualEffectView
            effectView?.effect = UIBlurEffect(style: .light)
            break
        }
    }
    
    private func frontWindow() -> UIWindow? {
        let enumerator = UIApplication.shared.windows.reversed()
        for window in enumerator {
            let windowOnMainScreen = (window.screen == UIScreen.main)
            let windowIsVisible = (!window.isHidden && window.alpha > 0)
            if windowOnMainScreen && windowIsVisible && window.isKeyWindow {
                return window
            }
        }
        return UIApplication.shared.delegate?.window ?? nil
    }
    
    //MARK: - UIGestureRecognizerDelegate
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if let state = (touch.view?.isDescendant(of: contentView)),
           state == true {
           return false
        }
        else {
            return true
        }
    }
    
}

extension NIOPopManager {
    
    private func autoDismiss() {
        if self.isAutoDismiss {
            DispatchQueue.init(label: "FDNotificationView-Dismiss").asyncAfter(wallDeadline: .now() + self.autoDismissDuration) {
                DispatchQueue.main.async {
                    self.dismiss()
                }
            }
        }
    }
    
}


