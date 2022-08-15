
import SwiftUI

/// An animation sequence allows the execution of several animation steps (and other functions) one after the other with
/// specifiable timing.
public class AnimationSequence {
    enum AnimationSequenceAction {
        /// An animation.
        case animation(function: () -> Void, animation: Animation?, duration: Double, delay: Double)
        
        /// A plain function.
        case function(function: () -> Void, delay: Double)
        
        /// A delay.
        case delay(delay: Double)
        
        /// A suspension point.
        case suspension
        
        /// The delay of this action.
        var delay: TimeInterval {
            switch self {
            case .animation(_, _, _, let delay):
                return delay
            case .function(_, let delay):
                return delay
            case .delay(let delay):
                return delay
            case .suspension:
                return 0
            }
        }
        
        /// The duration of this action.
        var duration: TimeInterval {
            switch self {
            case .animation(_, _, let duration, _):
                return duration
            default:
                return 0
            }
        }
        
        /// The function related to this action.
        var function: Optional<() -> Void> {
            switch self {
            case .animation(let function, _, _, _):
                return function
            case .function(let function, _):
                return function
            default:
                return nil
            }
        }
    }
    
    /// The animations to execute.
    var actions: [AnimationSequenceAction]
    
    /// The total animation duration.
    var totalDuration: Double
    
    /// The current execution index.
    var currentIndex: Int = 0
    
    /// Whether or not the execution of this sequence has been stopped.
    var stopped: Bool = false
    
    /// Default initializer.
    init(actions: [AnimationSequence.AnimationSequenceAction] = []) {
        self.actions = actions
        self.totalDuration = 0
    }
    
    /// Append an action.
    @discardableResult func append(animation: Animation?,
                                   duration: Double = 0.35,
                                   delay: Double = 0,
                                   function: @escaping () -> Void) -> AnimationSequence {
        actions.append(.animation(function: function, animation: animation, duration: duration, delay: delay))
        
        totalDuration += duration
        totalDuration += delay
        
        return self
    }
    
    /// Append an action.
    @discardableResult func append(delay: Double = 0,
                                   function: @escaping () -> Void) -> AnimationSequence {
        actions.append(.function(function: function, delay: delay))
        totalDuration += delay
        
        return self
    }
    
    /// Append a sequence element.
    @discardableResult func append(_ action: AnimationSequenceAction) -> AnimationSequence {
        actions.append(action)
        totalDuration += action.duration
        totalDuration += action.delay
        
        return self
    }
    
    /// Execute the animation sequence.
    @discardableResult func execute() -> Double {
        guard actions.count > 0 else {
            return 0
        }
        
        let action = actions[0]
        if action.delay.isZero {
            DispatchQueue.main.async {
                self.execute(at: 0)
            }
        }
        else {
            DispatchQueue.main.asyncAfter(deadline: .now() + action.delay) {
                self.execute(at: 0)
            }
        }
        
        return totalDuration
    }
    
    /// Execute this animation sequence without any animations.
    func executeWithoutAnimations() {
        for action in actions {
            action.function?()
        }
    }
    
    /// Continue a suspended sequence.
    func resume() {
        guard case .suspension = self.actions[self.currentIndex] else {
            fatalError("resuming a non-suspended sequence")
        }
        
        self.currentIndex += 1
        self.execute(at: self.currentIndex)
    }
    
    /// Stop this sequence.
    func stop() {
        self.stopped = true
    }
    
    /// Skip to the given point in the sequence.
    func skip(to index: Int) {
        guard self.actions.count > index else {
            fatalError("trying to skip to index \(index) in AnimationSequence with \(self.actions.count) actions")
        }
        
        self.stopped = true
        
        DispatchQueue.main.async {
            self.execute(at: index, force: true)
        }
    }
    
    /// Execute the specified animation and schedule the next one.
    private func execute(at index: Int, force: Bool = false) {
        guard force || !stopped else {
            return
        }
        
        let action = actions[index]
        self.currentIndex = index
        
        switch action {
        case .animation(let function, let animation, _, _):
            withAnimation(animation) {
                function()
            }
        case .function(let function, _):
            function()
        case .delay:
            break
        case .suspension:
            return
        }
        
        if index + 1 >= actions.count {
            return
        }
        
        let delay = action.duration + actions[index + 1].delay
        if delay.isZero {
            DispatchQueue.main.async {
                self.execute(at: index + 1, force: force)
            }
        }
        else {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.execute(at: index + 1, force: force)
            }
        }
    }
}

