/*
 *
 * Copyright (c) 2012, Ben Reeves. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301  USA
 */

#import "Assets.h"
#import "WalletDelegate.h"

@class JSValue,
       JSContext,
       BitcoinWallet,
       EthereumWallet,
       WalletConnectMetadata,
       WalletCryptoJS,
       WalletRepository;

@interface Wallet : NSObject

// Core Wallet Init Properties
@property (nonatomic, readonly, strong) JSContext *context;

@property (nonatomic, weak) id<WalletDelegate> delegate;

@property (nonatomic, copy) NSDictionary *accountInfo;
@property (nonatomic, assign) BOOL hasLoadedAccountInfo;

@property (nonatomic, assign) BOOL shouldLoadMetadata;

@property (nonatomic, copy) NSString *lastScannedWatchOnlyAddress;
@property (nonatomic, copy) NSString *lastImportedAddress;

// HD properties:
@property (nonatomic, assign) int emptyAccountIndex;
@property (nonatomic, assign) int recoveredAccountIndex;

@property (nonatomic, copy, nullable) void (^handleReload)(void);

@property (nonatomic, assign) BOOL isSyncing;
@property (nonatomic, assign) BOOL isNew;
@property (nonatomic, copy, nullable) NSDictionary<NSString *, id> *btcRates;

@property (nonatomic, readonly, strong, nonnull) BitcoinWallet * bitcoin;
@property (nonatomic, readonly, strong, nonnull) EthereumWallet * ethereum;
@property (nonatomic, readonly, strong, nonnull) WalletCryptoJS * crypto;
@property (nonatomic, strong, nonnull) WalletRepository * repository;
@property (nonatomic, strong, nonnull) WalletConnectMetadata * walletConnect;

- (instancetype)init;

# pragma mark - JS

/// Forces the JS layer to load - should be used to reset the context and rebind the methods
- (void)loadJS;
/// Load the JS - but only if needed - and return it.
- (JSContext *)loadContextIfNeeded;
/// Load the JS - but only if needed
- (void)loadJSIfNeeded;
- (BOOL)isInitialized;

# pragma mark - Login

- (void)fetchWalletWith:(nonnull NSString *)password;
- (void)loadWalletWithGuid:(nonnull NSString *)guid sharedKey:(nullable NSString *)sharedKey password:(nullable NSString *)password;
- (void)resetSyncStatus;

# pragma mark - Addresses

- (void)setLabel:(NSString *)label forLegacyAddress:(NSString *)address;

- (void)toggleArchiveLegacyAddress:(NSString *)address;
- (void)toggleArchiveAccount:(int)account assetType:(LegacyAssetType)assetType;

- (NSString *)labelForLegacyAddress:(NSString *)address assetType:(LegacyAssetType)assetType;

- (BOOL)isAddressArchived:(NSString *)address;

- (BOOL)isWatchOnlyLegacyAddress:(NSString*)address;

// Fetch String Array Of Addresses
- (NSArray *)activeLegacyAddresses:(LegacyAssetType)assetType;
- (NSArray *)allLegacyAddresses:(LegacyAssetType)assetType;


- (float)getStrengthForPassword:(NSString *)password;

- (BOOL)needsSecondPassword;
- (BOOL)validateSecondPassword:(NSString *)secondPassword;

- (void)getHistory;
- (void)getHistoryForAllAssets;

- (id)getLegacyAddressBalance:(NSString *)address assetType:(LegacyAssetType)assetType;

- (void)newAccount:(NSString *)password email:(NSString *)email;

- (int)getIndexOfActiveAccount:(int)account assetType:(LegacyAssetType)assetType;

# pragma mark - HD Wallet

- (void)upgradeToV3Wallet;
- (BOOL)hasAccount;
- (BOOL)didUpgradeToHd;

/**
 Returns the mnemonic used to generate the HD wallet.

 @param secondPassword the optional second password if set
 @return the mnemonic, or nil if the wallet is not yet initialized
 */
- (nullable NSString *)getMnemonic:(nullable NSString *)secondPassword;

- (BOOL)isRecoveryPhraseVerified;
- (void)markRecoveryPhraseVerifiedWithCompletion:(void (^ _Nullable)(void))completion error: (void (^ _Nullable)(void))error;
- (int)getDefaultAccountIndexForAssetType:(LegacyAssetType)assetType;
- (void)setDefaultAccount:(int)index assetType:(LegacyAssetType)assetType;
- (int)getActiveAccountsCount:(LegacyAssetType)assetType;
- (int)getAllAccountsCount:(LegacyAssetType)assetType;
- (BOOL)hasLegacyAddresses:(LegacyAssetType)assetType;
- (BOOL)isAccountArchived:(int)account assetType:(LegacyAssetType)assetType;
- (BOOL)isAccountNameValid:(NSString *)name;
- (uint64_t)getTotalActiveBalance;
- (uint64_t)getTotalBalanceForActiveLegacyAddresses:(LegacyAssetType)assetType;
- (id)getBalanceForAccount:(int)account assetType:(LegacyAssetType)assetType;

- (NSString *)getLabelForAccount:(int)account assetType:(LegacyAssetType)assetType;

- (NSString *)getXpubForAccount:(int)accountIndex assetType:(LegacyAssetType)assetType;

- (void)loading_stop;

- (int)getDefaultAccountLabelledAddressesCount;

# pragma mark - Settings

- (NSString *)getMobileMessage;
- (void)getAccountInfoAndExchangeRates;

# pragma mark - Bitcoin Cash

- (NSString *)fromBitcoinCash:(NSString *)address;
- (uint64_t)getBchBalance;
- (NSString *)bitcoinCashExchangeRate;

# pragma mark - Stellar

- (nullable NSArray *)getXlmAccounts;
- (void)saveXlmAccount:(nonnull NSString *)publicKey label:(nullable NSString *)label success:(void (^ _Nonnull)(void))success error:(void (^)(NSString *_Nonnull))error;

# pragma mark - Wallet Recovery

/// Recovers wallet associated with mnemonic passphrase, setting to it the given email and password and a new GUID.
- (void)recoverWithEmail:(nonnull NSString *)email password:(nonnull NSString *)recoveryPassword mnemonicPassphrase:(nonnull NSString *)mnemonicPassphrase;
/// Tries to recover wallet associated with mnemonic passphrase, reusing same GUID.
/// Succeeds if the wallet has the correct backup data in its metadata, otherwise fails with 'NO_METADATA' error.
- (void)recoverFromMetadataWithMnemonicPassphrase:(nonnull NSString *)mnemonicPassphrase;


@end
