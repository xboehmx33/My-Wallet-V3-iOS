// Copyright © Blockchain Luxembourg S.A. All rights reserved.

#import "BCEditAccountView.h"
#import "Blockchain-Swift.h"

@implementation BCEditAccountView

-(id)initWithAssetType:(LegacyAssetType)assetType
{
    UIWindow *window = [UIApplication sharedApplication].keyWindow;

    self = [super initWithFrame:CGRectMake(0, DEFAULT_HEADER_HEIGHT, window.frame.size.width, window.frame.size.height - DEFAULT_HEADER_HEIGHT)];

    if (self) {
        self.assetType = assetType;
        self.backgroundColor = [UIColor whiteColor];

        UILabel *labelLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 55, window.frame.size.width - 40, 25)];
        labelLabel.text = BC_STRING_NAME;
        labelLabel.textColor = [UIColor darkGrayColor];
        labelLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_LARGE];
        [self addSubview:labelLabel];

        _labelTextField = [[BCSecureTextField alloc] initWithFrame:CGRectMake(20, 95, window.frame.size.width - 40, 30)];
        _labelTextField.borderStyle = UITextBorderStyleRoundedRect;
        _labelTextField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        _labelTextField.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:_labelTextField.font.pointSize];
        _labelTextField.textColor = UIColor.gray5;
        _labelTextField.autocorrectionType = UITextAutocorrectionTypeNo;
        _labelTextField.spellCheckingType = UITextSpellCheckingTypeNo;
        [self addSubview:_labelTextField];

        [_labelTextField setReturnKeyType:UIReturnKeyDone];
        _labelTextField.delegate = self;

        UIButton *editAccountButton = [UIButton buttonWithType:UIButtonTypeCustom];
        editAccountButton.frame = CGRectMake(0, 0, window.frame.size.width, 46);
        editAccountButton.backgroundColor = UIColor.brandSecondary;
        [editAccountButton setTitle:BC_STRING_SAVE forState:UIControlStateNormal];
        [editAccountButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        editAccountButton.titleLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_LARGE];

        [editAccountButton addTarget:self action:@selector(editAccountClicked:) forControlEvents:UIControlEventTouchUpInside];

        _labelTextField.inputAccessoryView = editAccountButton;
    }

    return self;
}

# pragma mark - Button actions

- (IBAction)editAccountClicked:(id)sender
{
    // Remove whitespace
    NSString *label = [self.labelTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if (label.length == 0) {
        [AlertViewPresenter.shared standardNotifyWithTitle:BC_STRING_ERROR message:BC_STRING_YOU_MUST_ENTER_A_LABEL in:nil handler:nil];
        return;
    }

    if (label.length > 17) {
        // TODO i18n
        [AlertViewPresenter.shared standardNotifyWithTitle:BC_STRING_ERROR message:BC_STRING_LABEL_MUST_HAVE_LESS_THAN_18_CHAR in:nil handler:nil];
        return;
    }

    if (![WalletManager.sharedInstance.wallet isAccountNameValid:label]) {
        [AlertViewPresenter.shared standardErrorWithTitle:[LocalizationConstantsObjcBridge error] message:[LocalizationConstantsObjcBridge nameAlreadyInUse] in:nil handler:nil];
        [LoadingViewPresenter.shared hide];
        return;
    }

    [self.labelTextField resignFirstResponder];

    if (self.assetType == LegacyAssetTypeBitcoin) {
        [LoadingViewPresenter.shared showWith:[LocalizationConstantsObjcBridge syncingWallet]];
    }

    [self performSelector:@selector(changeAccountName:) withObject:label afterDelay:ANIMATION_DURATION];
}

- (void)changeAccountName:(NSString *)name
{
    [WalletManager.sharedInstance.wallet setLabelForAccount:self.accountIdx label:name assetType:self.assetType];
}

#pragma mark - Textfield Delegates

- (BOOL)textFieldShouldReturn:(UITextField*)aTextField
{
    [self editAccountClicked:nil];
    return YES;
}

@end
