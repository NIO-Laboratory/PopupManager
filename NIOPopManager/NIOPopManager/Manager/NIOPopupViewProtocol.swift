import Foundation
import UIKit


public protocol NIOPopupViewProtocol where Self: UIView {
    
    /// Ture 视图结构:
    ///    └── ContentView
    ///        └── MaskView (蒙层)
    ///            └── SuperView
    /// Flase 视图结构:
    ///     └── ContentView
    ///         └── SuperView
    var isShowMaskView: Bool { get }
    
    func beginAnimation(finish: @escaping ()->Void)
    
    func endAnimation(finish: @escaping ()->Void)
    
}






