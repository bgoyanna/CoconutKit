//
//  UIScrollView+HLSExtensions.h
//  CoconutKit
//
//  Created by Samuel Défago on 20.02.12.
//  Copyright (c) 2012 Hortis. All rights reserved.
//

@interface UIScrollView (HLSExtensions)

/**
 * Synchronize scrolling of a set of scroll views with the receiver (which becomes the "master scroll view").
 * When the master scroll view is scrolled, the other ones are automatically scrolled so that their relative 
 * content offset is identical to the one of the master (the relative content offset is defined as the absolute 
 * content offset divided by the scrolling range).
 * 
 * Note that the master scroll view is not scrolled if one of the scroll views it controls is scrolled.
 * This method is namely meant to be used in cases where one scroll view is enabled for interaction,
 * while the other ones (usually hidden behind it) are not meant to be used directly.
 *
 * Synchronizing scroll views makes several kinds of effects possible (most notably parallax scrolling). Note 
 * that a scroll view can be a master scroll view at most once, and that no mechanism has been implemented to
 * break dependency loops (scroll view A master of B which is itself master of A, for example). Such cases should
 * be quite rare, and taking proper measures would have been overkill.
 *
 * If the bounces parameter is set to YES (and if the master scroll view can itself bounce), synchronized
 * scroll views will go on scrolling when the master view bounces, otherwise they will stop.
 *
 * This method only synchronizes scrolling between scroll views. You still have to align them properly
 * and to set their respective content sizes to get the result you want.
 */
- (void)synchronizeWithScrollViews:(NSArray *)scrollViews bounces:(BOOL)bounces;

/**
 * Remove any previously existing synchronization set for the receiver
 */
- (void)removeSynchronization;

/**
 * When set to YES, the scroll view adjusts automatically so that it does not get covered by the keyboard (this works
 * for UIScrollView subclasses as well, e.g. UITextField). The scroll view content offset is also changed so that
 * responder views located within the scroll view (e.g. text fields, text views, search bars) stay visible when they
 * get the focus.
 *
 * Note that you MUST set a scroll view contentSize so that the scroll view can actually scroll. Moreover, the scroll 
 * view frame is changed when the keyboard is displayed, so be sure that the subview autoresizing masks are appropriately 
 * set, e.g.: 
 *   - if you want subviews to stay where they are, you should use fixed top margins
 *   - if you want subviews to stay centered, use a stretchable top margin
 *
 * Nested scroll views are supported. If several scroll views avoiding the keyboard are nested, the top parent will
 * be the only only one to avoid the keyboard
 *
 * The default value is NO
 */
@property (nonatomic, assign, getter=isAvoidingKeyboard) BOOL avoidingKeyboard;

@end
