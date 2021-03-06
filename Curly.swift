//
//  Curly.swift
//  Curly
//
//  Created by Adolfo Rodriguez on 2014-11-04.
//  Copyright (c) 2014 Wircho. All rights reserved.
//

import Foundation

import UIKit

//MARK: Constants

var CurlyAssociatedDelegateHandle: UInt8 = 0
var CurlyAssociatedDelegateDictionaryHandle: UInt8 = 0
var CurlyAssociatedDeinitDelegateArrayHandle: UInt8 = 0

//MARK: Extensions

public extension UIAlertView {
    public func show(#clicked:(alertView:UIAlertView,buttonIndex:Int)->Void) {
        self.show(clicked:clicked,willPresent:nil, didPresent: nil, willDismiss: nil, didDismiss: nil, canceled: nil, shouldEnableFirstOtherButton: nil)
    }

    public func show(#willDismiss:(alertView:UIAlertView,buttonIndex:Int)->Void) {
        self.show(clicked:nil,willPresent:nil, didPresent: nil, willDismiss:willDismiss, didDismiss: nil, canceled: nil, shouldEnableFirstOtherButton: nil)
    }

    public func show(#didDismiss:(alertView:UIAlertView,buttonIndex:Int)->Void) {
        self.show(clicked:nil,willPresent:nil, didPresent: nil, willDismiss: nil, didDismiss: didDismiss, canceled: nil, shouldEnableFirstOtherButton: nil)
    }

    public func show(#clicked:((alertView:UIAlertView,buttonIndex:Int)->Void)?,
        willPresent:((alertView:UIAlertView)->Void)?,
        didPresent:((alertView:UIAlertView)->Void)?,
        willDismiss:((alertView:UIAlertView,buttonIndex:Int)->Void)?,
        didDismiss:((alertView:UIAlertView,buttonIndex:Int)->Void)?,
        canceled:((alertView:UIAlertView)->Void)?,
        shouldEnableFirstOtherButton:((alertView:UIAlertView)->Bool)?) {

            let delegate = Curly.AlertViewDelegate(clicked: clicked, willPresent: willPresent, didPresent: didPresent, willDismiss: willDismiss, didDismiss: didDismiss, canceled: canceled, shouldEnableFirstOtherButton: shouldEnableFirstOtherButton)

            self.delegate = delegate
            
            objc_setAssociatedObject(self, &CurlyAssociatedDelegateHandle, delegate, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))

            self.show()

    }
}

public extension UINavigationController {
    public func setDelegate(#willShow:((viewController:UIViewController,animated:Bool)->Void)?, didShow:((viewController:UIViewController,animated:Bool)->Void)? = nil) {
        
        let delegate = Curly.NavigationControllerDelegate(willShow: willShow, didShow: didShow)
        
        self.delegate = delegate
        
        objc_setAssociatedObject(self, &CurlyAssociatedDelegateHandle, delegate, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
        
    }
}

public extension UIViewController {
    
    
    public func performSegueWithIdentifier(identifier: String?, sender: AnyObject?, preparation:(UIStoryboardSegue,AnyObject?)->Void) {
        
        if let id = identifier {
            Curly.registerSeguePreparation(id, viewController: self, preparation: preparation)
            
            self.performSegueWithIdentifier(id, sender: sender)
            
        }
        
        
    }
    
    public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        if let id = segue.identifier {
            if let (index,preparation) = Curly.getSeguePreparation(id, viewController: self) {
                preparation(segue,sender)
                Curly.unregisterSeguePreparation(index)
            }
        }

    }
}

public extension UIGestureRecognizer {
    
    //Objective C support
    convenience init (block:(UIGestureRecognizer)->Void) {
        self.init(closure:block)
    }
    
    convenience init<T:UIGestureRecognizer>(closure:(T)->Void) {
        let delegate = Curly.GestureRecognizerDelegate(recognized: closure)
        
        self.init(target: delegate, action: "recognizedGestureRecognizer:")
        
        
        objc_setAssociatedObject(self, &CurlyAssociatedDelegateHandle, delegate, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
    }
}

public extension UIControl {
    
    //Objective C support
    public func addAction(events:UIControlEvents,block:(UIControl)->Void)
    {
        self.addAction(events, closure: block)
    }
    
    public func addAction<T:UIControl>(events:UIControlEvents,closure:(T)->Void) {

        var delegateDictionary = objc_getAssociatedObject(self, &CurlyAssociatedDelegateDictionaryHandle) as [UInt:[Curly.ControlDelegate]]!

        if delegateDictionary == nil {
            delegateDictionary = [:]
        }

        if delegateDictionary[events.rawValue] == nil {
            delegateDictionary[events.rawValue] = []
        }

        let delegate = Curly.ControlDelegate(received: closure)

        self.addTarget(delegate, action:Selector("recognizedControlEvent:"), forControlEvents: events)

        delegateDictionary[events.rawValue]!.append(delegate)

        objc_setAssociatedObject(self, &CurlyAssociatedDelegateDictionaryHandle, delegateDictionary, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))

    }

    public func removeActions(events:UIControlEvents) {
        
        var delegateDictionary = objc_getAssociatedObject(self, &CurlyAssociatedDelegateDictionaryHandle) as [UInt:[Curly.ControlDelegate]]!

        if delegateDictionary == nil {
            return
        }

        if let array = delegateDictionary[events.rawValue] {
            for delegate in array {
                self.removeTarget(delegate, action: "recognizedControlEvent:", forControlEvents: events)
            }
        }
        
        delegateDictionary[events.rawValue] = nil

        objc_setAssociatedObject(self, &CurlyAssociatedDelegateDictionaryHandle, delegateDictionary, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))

    }
}

public extension NSObject {
    
    public func deinited(closure:()->Void) {
        var deinitArray = objc_getAssociatedObject(self, &CurlyAssociatedDeinitDelegateArrayHandle) as [Curly.DeinitDelegate]!
        
        if deinitArray == nil {
            deinitArray = []
        }
        
        deinitArray.append(Curly.DeinitDelegate(deinited: closure))
        
        objc_setAssociatedObject(self, &CurlyAssociatedDeinitDelegateArrayHandle, deinitArray, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
        
    }
    
    public func removeDeinitObservers() {
        var deinitArray = objc_getAssociatedObject(self, &CurlyAssociatedDeinitDelegateArrayHandle) as [Curly.DeinitDelegate]!
        
        if deinitArray == nil {
            return
        }
        
        for delegate in deinitArray {
            delegate.deinited = nil
        }
        
        objc_setAssociatedObject(self, &CurlyAssociatedDeinitDelegateArrayHandle, nil, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
    }
    
}

//MARK: Curly class

public class Curly : NSObject {
    
    //MARK: Performing actions with delay
    
    private struct Delay {
        static var delayKeys:[String:Int] = [:]
        static var delayCounter:Int = 0
    }
    
    class func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
    
    class func delay(delay:Double,key:String,closure:()->()) {
        Delay.delayCounter += 1
        var counter = Delay.delayCounter
        Delay.delayKeys[key] = counter
        
        self.delay(delay) {
            if let value = self.Delay.delayKeys[key] {
                if value == counter {
                    closure()
                    self.stopDelay(key)
                }
            }
        }
    }
    
    class func stopDelay(key:String) {
        Delay.delayKeys[key] = nil
    }
    
    //MARK: UIViewController, UIStoryboardSegue

    private struct SeguePreparation {
        let identifier:String
        let viewController:UIViewController
        let preparation:(UIStoryboardSegue,AnyObject?)->Void
        static var preparations:[SeguePreparation] = []
    }

    private class func registerSeguePreparation(identifier:String, viewController:UIViewController, preparation:(UIStoryboardSegue, AnyObject?) -> Void) {

        if let (index,_) = getSeguePreparation(identifier, viewController: viewController) {
            unregisterSeguePreparation(index)
        }
        
        SeguePreparation.preparations.append( SeguePreparation(identifier: identifier, viewController: viewController, preparation: preparation))
        
    }
    
    private class func unregisterSeguePreparation(index:Int) {
        
        SeguePreparation.preparations.removeAtIndex(index)
        
    }

    private class func getSeguePreparation(identifier:String, viewController:UIViewController) -> (Int,((UIStoryboardSegue, AnyObject?) -> Void))? {
        
        for var i = 0; i < SeguePreparation.preparations.count; i += 1 {
            let prep = SeguePreparation.preparations[i]
            if prep.identifier == identifier && prep.viewController == viewController {
                return (i,prep.preparation)
            }
        }
        
        return nil
        
    }

    //MARK: UINavigationController, UINavigationControllerDelegate
    
    private class NavigationControllerDelegate: NSObject, UINavigationControllerDelegate {
        
        var willShow:((viewController:UIViewController,animated:Bool)->Void)?
        var didShow:((viewController:UIViewController,animated:Bool)->Void)?
        
        init(willShow v_willShow:((viewController:UIViewController,animated:Bool)->Void)?, didShow v_didShow:((viewController:UIViewController,animated:Bool)->Void)?) {
            willShow = v_willShow
            didShow = v_didShow
            super.init()
        }
        
        private func navigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {
            if willShow != nil {
                willShow!(viewController: viewController, animated: animated);
            }
        }
        
        private func navigationController(navigationController: UINavigationController, didShowViewController viewController: UIViewController, animated: Bool) {
            if didShow != nil {
                didShow!(viewController: viewController, animated: animated);
            }
        }
        
    }
    
    //MARK: UIAlertView, UIAlertViewDelegate
    
    private class AlertViewDelegate: NSObject, UIAlertViewDelegate {

        var clicked:((alertView:UIAlertView,buttonIndex:Int)->Void)?
        var willPresent:((alertView:UIAlertView)->Void)?
        var didPresent:((alertView:UIAlertView)->Void)?
        var willDismiss:((alertView:UIAlertView,buttonIndex:Int)->Void)?
        var didDismiss:((alertView:UIAlertView,buttonIndex:Int)->Void)?
        var canceled:((alertView:UIAlertView)->Void)?
        var shouldEnableFirstOtherButton:((alertView:UIAlertView)->Bool)?

        init(clicked v_clicked:((alertView:UIAlertView,buttonIndex:Int)->Void)?,
            willPresent v_willPresent:((alertView:UIAlertView)->Void)?,
            didPresent v_didPresent:((alertView:UIAlertView)->Void)?,
            willDismiss v_willDismiss:((alertView:UIAlertView,buttonIndex:Int)->Void)?,
            didDismiss v_didDismiss:((alertView:UIAlertView,buttonIndex:Int)->Void)?,
            canceled v_canceled:((alertView:UIAlertView)->Void)?,
            shouldEnableFirstOtherButton v_shouldEnableFirstOtherButton:((alertView:UIAlertView)->Bool)?) {
                clicked = v_clicked
                willPresent = v_willPresent
                didPresent = v_didPresent
                willDismiss = v_willDismiss
                didDismiss = v_didDismiss
                canceled = v_canceled
                shouldEnableFirstOtherButton = v_shouldEnableFirstOtherButton
                super.init()
        }

        private func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
            if clicked != nil {
                clicked!(alertView: alertView,buttonIndex: buttonIndex)
            }
        }

        private func alertViewCancel(alertView: UIAlertView) {
            if canceled == nil {
                alertView.dismissWithClickedButtonIndex(alertView.cancelButtonIndex, animated: false)
            }else{
                canceled!(alertView:alertView)
            }
        }

        private func willPresentAlertView(alertView: UIAlertView) {
            if willPresent != nil {
                willPresent!(alertView: alertView)
            }
        }

        private func didPresentAlertView(alertView: UIAlertView) {
            if didPresent != nil {
                didPresent!(alertView: alertView)
            }
        }

        private func alertView(alertView: UIAlertView, willDismissWithButtonIndex buttonIndex: Int) {
            if willDismiss != nil {
                willDismiss!(alertView: alertView, buttonIndex: buttonIndex)
            }
        }

        private func alertView(alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
            if didDismiss != nil {
                didDismiss!(alertView: alertView, buttonIndex: buttonIndex)
            }
        }
        
        private func alertViewShouldEnableFirstOtherButton(alertView: UIAlertView) -> Bool {
            if shouldEnableFirstOtherButton == nil {
                return true
            }else{
                return shouldEnableFirstOtherButton!(alertView: alertView)
            }
        }
    }
    
    //MARK: Gesture recognizer delegate
    
    public class GestureRecognizerDelegate: NSObject {
        
        let recognized:(UIGestureRecognizer)->Void
        
        public func recognizedGestureRecognizer(gr:UIGestureRecognizer) {
            recognized(gr)
        }
        
        init<T:UIGestureRecognizer>(recognized:(T)->Void) {
            self.recognized = { (gestureRecognizer:UIGestureRecognizer) -> Void in
                if let gr = gestureRecognizer as? T {
                    recognized(gr)
                }
            }
            
            super.init()
        }
    }
    
    //MARK: UIControl delegate
    
    public class ControlDelegate: NSObject {
        
        public let received:(UIControl)->Void
        
        public func recognizedControlEvent(ctl:UIControl) {
            received(ctl)
        }
        
        init<T:UIControl>(received:(T)->Void) {
            self.received = { (control:UIControl) -> Void in
                if let ctl = control as? T {
                    received(ctl)
                }
                
            }
            super.init()
        }
    }
    
    //MARK Deinit delegate
    
    public class DeinitDelegate: NSObject {
        
        public var deinited:(()->Void)!
        
        deinit {
            if deinited != nil {
                deinited()
            }
        }
        
        init(deinited:()->Void) {
            self.deinited = deinited
            super.init()
        }
        
    }
    
}



