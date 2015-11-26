//
//  RWViewController.m
//  RWReactivePlayground
//
//  Created by Colin Eberhardt on 18/12/2013.
//  Copyright (c) 2013 Colin Eberhardt. All rights reserved.
//

//Spliting: 信号可以有多个订阅者，且作为资源服务于序列化管道的多个步骤。
//Combining: 多个信号可以组合起来创建新的信号。

#import "RWViewController.h"
#import "RWDummySignInService.h"

@interface RWViewController ()

@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *signInButton;
@property (weak, nonatomic) IBOutlet UILabel *signInFailureText;

//@property (nonatomic) BOOL passwordIsValid;
//@property (nonatomic) BOOL usernameIsValid;
@property (strong, nonatomic) RWDummySignInService *signInService;

@end

@implementation RWViewController

- (void)viewDidLoad {
  [super viewDidLoad];
    
#pragma mark - 用RAC操作
    /**
     *  用RAC操作
     */
//    [self.usernameTextField.rac_textSignal subscribeNext:^(id x) {
//        NSLog(@"%@",x);
//    } error:^(NSError *error) {
//        NSLog(@"error");
//    } completed:^{
//        NSLog(@"finish");
//    }];
    
#pragma mark - 过滤器
    //过滤器
    /**
     
     
//    [
     [[self.usernameTextField.rac_textSignal filter:^BOOL(id value) {
        NSString *string = value;
        //在这里如果块返回值是真的话就返回一个RACSignal的实例 否则返回一个空的实例 形似一个管道
        return string.length > 3;
    }]
//      map:^id(id value) {
//        NSString *text = value;
//        return @(text.length);
//    }]
     subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
     */
#pragma mark - 映射(与过滤并没有先后关系，都返回一个RACSignal对象)
//    [[[self.usernameTextField.rac_textSignal map:^id(id value) {
//        NSString *text = value;
//        return @(text.length);
//    }] filter:^BOOL(NSNumber *length) {
//        return [length intValue] > 3;
//    }] subscribeNext:^(id x) {
//        NSLog(@"%@",x);
//    }];
    
    
//    第一件事就是创建一对信号来校验用户名与密码的输入是否有效。
    RACSignal *validUserName = [self.usernameTextField.rac_textSignal map:^id(NSString *text) {
        return @([self isValidUsername:text]);
    }];
    RACSignal *validPassword = [self.passwordTextField.rac_textSignal map:^id(NSString *text) {
        return @([self isValidPassword:text]);
    }];
//    我们将信号的输出值赋值给文本输入框的backgroundColor属性
    /**
    
    [[validUserName map:^id(NSNumber *isValid) {
        return [isValid boolValue]? [UIColor redColor]:[UIColor yellowColor];
    }]subscribeNext:^(UIColor *x) {
        self.usernameTextField.backgroundColor = x;
    }];
    
    [[validPassword map:^id(NSNumber *isValid) {
        return [isValid boolValue]? [UIColor greenColor]:[UIColor brownColor];
    }] subscribeNext:^(id x) {
        UIColor *bgColor = x;
        self.passwordTextField.backgroundColor = bgColor;
    }];
    */
#pragma mark - 使用宏的RAC
    //RAC宏我们将信号的输入值指派给对象的属性。它带有两个参数，第一个参数是对象，第二个参数是对象的属性名。每次信号发送下一个事件时，其输出值都会指派给给定的属性。这是个非常优雅的解决方案，对吧？
    RAC(self.passwordTextField, backgroundColor) = [validPassword map:^id(NSNumber *value) {
        return [value boolValue] ? [UIColor redColor]:[UIColor yellowColor];
    }];
    RAC(self.usernameTextField, backgroundColor) = [validUserName map:^id(NSNumber *value) {
       return [value boolValue] ? [UIColor greenColor]:[UIColor brownColor];
    }];
    
    
#pragma mark - 组合信号
    /**
     *  组合信号
     *  使用了combineLatest:reduce:方法来组合validUsernameSignal与validPasswordSignal最后输出的值，并生成一个新的信号。每次两个源信号中的一个输出新值时，reduce块都会被执行，而返回的值会作为组合信号的下一个值。
     */
    //注意：RACSignal组合方法可以组合任何数量的信号，而reduce块的参数会对应每一个信号。
    RACSignal *signUpActiveSignal = [RACSignal combineLatest:@[validUserName, validPassword] reduce:^id(NSNumber *usernameValid, NSNumber *passwordValid){
        return @([usernameValid boolValue] && [passwordValid boolValue]);
    }];
    
    [signUpActiveSignal subscribeNext:^(NSNumber *bothIsValid) {
        self.signInButton.enabled = [bothIsValid boolValue];
    }];
    
    
    [self updateUIState];
  
  self.signInService = [RWDummySignInService new];
  
  // handle text changes for both text fields
//  [self.usernameTextField addTarget:self action:@selector(usernameTextFieldChanged) forControlEvents:UIControlEventEditingChanged];
//  [self.passwordTextField addTarget:self action:@selector(passwordTextFieldChanged) forControlEvents:UIControlEventEditingChanged];
  
  // initially hide the failure message
  self.signInFailureText.hidden = YES;
//    添加附加操作(side-effects)  防止按钮多次点击 用doNext
//    我们可以看到在按钮点击事件后添加了doNext:步骤。注意doNext:并不返回一个值，因为它是附加操作。它完成时不改变事件。只是一个附加操作
    [[[[self.signInButton rac_signalForControlEvents:UIControlEventTouchUpInside]doNext:^(id x) {
        self.signInButton.enabled = NO;
        self.signInFailureText.hidden = YES;
        //如果要调用自定义信号 扁平化映射
    }]flattenMap:^RACStream *(id value) {
        return [self signInSignal];
    }] subscribeNext:^(NSNumber *x) {
        NSLog(@"%@",x);
         self.signInButton.enabled = YES;
        self.signInFailureText.hidden = [x boolValue];
        if ([x boolValue]) {
            [self performSegueWithIdentifier:@"signInSuccess" sender:self];
        }
    }];
    
    //没作doNext之前
    
//    [[[self.signInButton rac_signalForControlEvents:UIControlEventTouchUpInside] flattenMap:^RACStream *(id value) {
//        return [self signInSignal];
//    }] subscribeNext:^(id x) {
//        NSLog(@"%@",x);
//        if (x) {
//            [self performSegueWithIdentifier:@"signInSuccess" sender:self];
//        }
//    }];
    
}

- (BOOL)isValidUsername:(NSString *)username {
  return username.length > 3;
}

- (BOOL)isValidPassword:(NSString *)password {
  return password.length > 3;
}

//- (IBAction)signInButtonTouched:(id)sender {
//  // disable all UI controls
//  self.signInButton.enabled = NO;
//  self.signInFailureText.hidden = YES;
//  
//  // sign in
//  [self.signInService signInWithUsername:self.usernameTextField.text
//                            password:self.passwordTextField.text
//                            complete:^(BOOL success) {
//                              self.signInButton.enabled = YES;
//                              self.signInFailureText.hidden = success;
//                              if (success) {
//                                [self performSegueWithIdentifier:@"signInSuccess" sender:self];
//                              }
//                            }];
//}

- (RACSignal*)signInSignal{
//    这个block的返回类型是一个RACDisposable对象，它允许我们执行一些清理任务，这些操作可能发生在订阅取消或丢弃时。上面这个这个信号没有任何清理需求，所以返回nil。
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [self.signInService signInWithUsername:self.usernameTextField.text password:self.passwordTextField.text complete:^(BOOL success) {
// 我们也可以发送多个next事件，这些事件由一个error事件或complete事件结束
            [subscriber sendNext:@(success)];
            [subscriber sendCompleted];
        }];
        return nil;
    }];
}

// updates the enabled state and style of the text fields based on whether the current username
// and password combo is valid
- (void)updateUIState {
//  self.usernameTextField.backgroundColor = self.usernameIsValid ? [UIColor clearColor] : [UIColor yellowColor];
//  self.passwordTextField.backgroundColor = self.passwordIsValid ? [UIColor clearColor] : [UIColor yellowColor];
//  self.signInButton.enabled = self.usernameIsValid && self.passwordIsValid;
}

//- (void)usernameTextFieldChanged {
//  self.usernameIsValid = [self isValidUsername:self.usernameTextField.text];
//  [self updateUIState];
//}

//- (void)passwordTextFieldChanged {
//  self.passwordIsValid = [self isValidPassword:self.passwordTextField.text];
//  [self updateUIState];
//}

@end
