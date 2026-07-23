
#import <UIKit/UIKit.h>

#define DLGMemUIViewCellID      @"DLGMemUIViewCell"
#define DLGMemUIViewCellHeight  32

@protocol DLGMemUIViewCellDelegate <NSObject>

- (void)DLGMemUIViewCellModify:(NSString *)address value:(NSString *)value;
- (void)DLGMemUIViewCellViewMemory:(NSString *)address;

@end

@interface DLGMemUIViewCell : UITableViewCell

@property (nonatomic, weak) id<DLGMemUIViewCellDelegate> delegate;
@property (nonatomic, weak) id<UITextFieldDelegate> textFieldDelegate;
@property (nonatomic) NSString *address;
@property (nonatomic) NSString *value;
@property (nonatomic) BOOL modifying;
@property (nonatomic, readonly) UIButton *checkbox;
@property (nonatomic, copy) void (^checkboxChanged)(BOOL checked);
- (void)setShowsCheckbox:(BOOL)show;
- (void)setCheckboxChecked:(BOOL)checked;

@end
