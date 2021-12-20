// MARK: Imports

var Buffer = Blockchain.Buffer;
var MyWallet = Blockchain.MyWallet;
var WalletStore = Blockchain.WalletStore;
var WalletCrypto = Blockchain.WalletCrypto;
var BlockchainAPI = Blockchain.API;
var BlockchainSettingsAPI = Blockchain.BlockchainSettingsAPI;
var Helpers = Blockchain.Helpers;
var WalletNetwork = Blockchain.WalletNetwork;
var Address = Blockchain.Address;
var Bitcoin = Blockchain.Bitcoin;
var BigInteger = Blockchain.BigInteger;
var BIP39 = Blockchain.BIP39;
var Networks = Blockchain.Networks;
var ECDSA = Blockchain.ECDSA;
var Metadata = Blockchain.Metadata;

// MARK: WalletOptions

function WalletOptions (api) {
    var optionsCache = {};

    this.getValue = function () {
      return optionsCache[this.getFileName()];
    };

    this.fetch = function () {
      var name = this.getFileName();
      var readJson = function (res) { return res.json(); }
      var cacheOptions = function (opts) { optionsCache[name] = opts; return opts; };
      return fetch(api.ROOT_URL + 'Resources/' + name).then(readJson).then(cacheOptions);
    };

    this.getFileName = function () {
      return 'wallet-options.json';
    };
}
  
// MARK: BlockchainAPI

APP_NAME = 'javascript_iphone_app';
APP_VERSION = '3.0';
API_CODE = '35e77459-723f-48b0-8c9e-6e9e8f54fbd3';
// Don't use minified JS files when loading web worker scripts
min = false;

// Set the API code for the iOS Wallet for the server calls
BlockchainAPI.API_CODE = API_CODE;
BlockchainAPI.AJAX_TIMEOUT = 30000; // 30 seconds
BlockchainAPI.API_ROOT_URL = 'https://api.blockchain.info/'

// MARK: Properties:

var currentPayment = null;
var currentBitcoinCashPayment = null;
var walletOptions = new WalletOptions(BlockchainAPI);

// MARK: Overrides

// MARK: - MyWallet overrides

MyWallet.setIsInitialized = function () {
    if (MyWallet.getIsInitialized()) {
        return;
    }
    MyWallet.updateToInitialized();
    console.log("Wallet is initialized");
    objc_set_is_initialized();
};

MyWallet.decryptAndInitializeWallet = function (success, error, decryptSuccess) {
    var encryptedWalletData = WalletStore.getEncryptedWalletData();
    if (encryptedWalletData === undefined || encryptedWalletData === null || encryptedWalletData.length === 0) {
      error('No Wallet Data To Decrypt');
      return;
    };

    var init = function () {
        MyWallet.setIsInitialized();
    };

    var resultJSON = objc_decrypt_wallet(encryptedWalletData, WalletStore.getPassword());
    var result = JSON.parse(resultJSON);
    if (result.success != undefined) {
        var decryptedPayload = JSON.parse(result.success);
        MyWallet.handleDecryptAndInitializeWalletSuccess(decryptedPayload, success, decryptSuccess, init);
    } else {
        var errorMessage = 'Error decrypting wallet, please check that your password is correct';
        if (result.failure != undefined) {
            errorMessage = result.failure;
        };
        MyWallet.handleDecryptAndInitializeWalletError(
            error,
            errorMessage
        );
    };
};

// MARK: - WalletCrypto overrides

WalletCrypto.scrypt = function(passwd, salt, N, r, p, dkLen, callback) {
    if (typeof(passwd) !== 'string') {
        passwd = passwd.toJSON().data;
    }

    if (typeof(salt) !== 'string') {
        salt = salt.toJSON().data;
    }

    objc_crypto_scrypt_salt_n_r_p_dkLen(passwd, salt, N, r, p, dkLen, function(buffer) {
      var bytes = new Buffer(buffer, 'hex');
      callback(bytes);
    }, function(e) {
      error(''+e);
    });
};

WalletCrypto.stretchPassword = function (password, salt, iterations, keylen) {
    var retVal = objc_sjcl_misc_pbkdf2(password, salt.toJSON().data, iterations, (keylen || 256) / 8);
    return new Buffer(retVal, 'hex');
}

// MARK: - BIP39 overrides

BIP39.mnemonicToSeed = function(mnemonic, enteredPassword) {
    var mnemonicBuffer = new Buffer(mnemonic, 'utf8')
    var saltBuffer = new Buffer(BIP39.salt(enteredPassword), 'utf8');
    var retVal = objc_pbkdf2_sync(mnemonicBuffer, saltBuffer, 2048, 64);
    return new Buffer(retVal, 'hex');
}

BIP39.mnemonicToSeedHex = function(mnemonic, enteredPassword) {
    return BIP39.mnemonicToSeed(mnemonic, enteredPassword).toString('hex');
}

// MARK: - Metadata overrides

Metadata.verify = function (address, signature, message) {
    return objc_message_verify(address, signature.toString('hex'), message);
}

Metadata.sign = function (keyPair, message) {
    let privateKey = keyPair.privateKey.toString('base64');
    let compressed = keyPair.compressed;
    let signed = objc_message_sign(privateKey, message, compressed);
    let result = new Buffer(signed, 'hex');
    return result
}

// MARK: WalletStore

// Register for JS event handlers and forward to Obj-C handlers
WalletStore.addEventListener(function (event, obj) {
    var eventsWithObjCHandlers = ["did_multiaddr", "did_fail_set_guid", "error_restoring_wallet", "logging_out", "on_backup_wallet_start", "on_backup_wallet_error", "on_backup_wallet_success", "on_tx_received", "ws_on_close", "ws_on_open", "did_load_wallet"];

    if (event == 'msg') {
        if (obj.type == 'error') {

            if (obj.message != "For Improved security add an email address to your account.") {
                // Cancel busy view in case any error comes in - except for add email, that's handled differently in makeNotice
                objc_loading_stop();
            }

            if (obj.message == "Error Downloading Account Settings") {
                on_error_downloading_account_settings();
                return;
            }

            // Some messages are JSON objects and the error message is in the map
            try {
                var messageJSON = JSON.parse(obj.message);
                if (messageJSON && messageJSON.initial_error) {
                    objc_makeNotice_id_message(''+obj.type, ''+obj.code, ''+messageJSON.initial_error);
                    return;
                }
            } catch (e) {
            }
            objc_makeNotice_id_message(''+obj.type, ''+obj.code, ''+obj.message);
        } else if (obj.type == 'success') {
            objc_makeNotice_id_message(''+obj.type, ''+obj.code, ''+obj.message);
        }
            return;
    }

    if (eventsWithObjCHandlers.indexOf(event) == -1) {
        return;
    }

    var codeToExecute = ('objc_'.concat(event)).concat('()');
    var tmpFunc = new Function(codeToExecute);
    tmpFunc(obj);
});

// MARK: MyWalletPhone

var MyWalletPhone = {};

MyWalletPhone.upgradeToV4 = function() {
    var success = function () {
        console.log('Upgraded V3 wallet to V4 wallet');
        MyWallet.wallet.getHistory();
        objc_loading_stop();
        objc_upgrade_V4_success();
    };

    var error = function (e) {
        console.log('Error upgrading legacy wallet to V4 wallet: ' + e);
        objc_loading_stop();
        objc_upgrade_V4_error();
    };

    if (MyWallet.wallet.isDoubleEncrypted) {
        MyWalletPhone.getSecondPassword(function (pw) {
          MyWallet.wallet.upgradeToV4(pw, success, error);
        });
    } else {
        MyWallet.wallet.upgradeToV4(null, success, error);
    }
};

MyWalletPhone.upgradeToV3 = function(firstAccountName) {
    var success = function () {
        console.log('Upgraded legacy wallet to HD wallet');

        MyWallet.wallet.getHistory();
        objc_loading_stop();
        objc_upgrade_V3_success();
    };

    var error = function (e) {
        console.log('Error upgrading legacy wallet to HD wallet: ' + e);
        objc_loading_stop();
        objc_upgrade_V3_error();
    };

    if (MyWallet.wallet.isDoubleEncrypted) {
        MyWalletPhone.getSecondPassword(function (pw) {
          MyWallet.wallet.upgradeToV3(firstAccountName, pw, success, error);
        });
    }
    else {
        MyWallet.wallet.upgradeToV3(firstAccountName, null, success, error);
    }
};

MyWalletPhone.getActiveAccounts = function() {
    if (!MyWallet.wallet.isUpgradedToHD) {
        console.log('Warning: Getting accounts when wallet has not upgraded!');
        return [];
    }

    var accounts = MyWallet.wallet.hdwallet.accounts;

    var activeAccounts = accounts.filter(function(account) { return account.archived === false; });

    return activeAccounts;
};

MyWalletPhone.getIndexOfActiveAccount = function(num) {
    if (!MyWallet.wallet.isUpgradedToHD) {
        console.log('Warning: Getting accounts when wallet has not upgraded!');
        return 0;
    }

    var activeAccounts = MyWalletPhone.getActiveAccounts();

    var realNum = activeAccounts[num].index;

    return realNum;
};

MyWalletPhone.getAccountIndex = function(address) {
    var accounts = MyWallet.wallet.hdwallet.accounts;
    
    var index = null;
    for (var i = 0; i < accounts.length; i++) {
        var account = accounts[i];
        if (account.receiveAddress === address) {
            index = account.index;
        }
    }

    if (index) {
        return index;
    }

    return 0;
};

MyWalletPhone.getDefaultAccountIndex = function() {
    if (!MyWallet.wallet.isUpgradedToHD) {
        console.log('Warning: Getting accounts when wallet has not upgraded!');
        return 0;
    }

    var accounts = MyWallet.wallet.hdwallet.accounts;

    var index = MyWallet.wallet.hdwallet.defaultAccountIndex;

    var defaultAccountIndex = null;
    for (var i = 0; i < accounts.length; i++) {
        var account = accounts[i];
        if (account.index === index) {
            defaultAccountIndex = i;
        }
    }

    if (defaultAccountIndex) {
        return defaultAccountIndex;
    }

    return 0;
}

MyWalletPhone.setDefaultAccount = function(num) {
    if (!MyWallet.wallet.isUpgradedToHD) {
        console.log('Warning: Getting accounts when wallet has not upgraded!');
        return 0;
    }

    MyWallet.wallet.hdwallet.defaultAccountIndex = num;
}

MyWalletPhone.getActiveAccountsCount = function() {
    if (!MyWallet.wallet.isUpgradedToHD) {
        console.log('Warning: Getting accounts when wallet has not upgraded!');
        return 0;
    }

    var activeAccounts = MyWalletPhone.getActiveAccounts();

    return activeAccounts.length;
};

MyWalletPhone.getAllAccountsCount = function() {
    if (!MyWallet.wallet.isUpgradedToHD) {
        console.log('Warning: Getting accounts when wallet has not upgraded!');
        return 0;
    }

    return MyWallet.wallet.hdwallet.accounts.length;
};

MyWalletPhone.getBalanceForAccount = function(num) {
    if (!MyWallet.wallet.isUpgradedToHD) {
        console.log('Warning: Getting accounts when wallet has not upgraded!');
        return 0;
    }

    return MyWallet.wallet.hdwallet.accounts[num].balance;
};

MyWalletPhone.totalActiveBalance = function() {
    if (!MyWallet.wallet.isUpgradedToHD) {
        console.log('Warning: Getting accounts when wallet has not upgraded!');
        return MyWallet.wallet.balanceSpendableActiveLegacy;
    }

    return MyWallet.wallet.hdwallet.balanceActiveAccounts + MyWallet.wallet.balanceSpendableActiveLegacy;
}

MyWalletPhone.getLabelForAccount = function(num) {
    if (!MyWallet.wallet.isUpgradedToHD) {
        console.log('Warning: Getting accounts when wallet has not upgraded!');
        return '';
    }

    return MyWallet.wallet.hdwallet.accounts[num].label;
};

MyWalletPhone.setLabelForAccount = function(num, label) {
    if (!MyWallet.wallet.isUpgradedToHD) {
        console.log('Warning: Getting accounts when wallet has not upgraded!');
        return;
    }

    MyWallet.wallet.hdwallet.accounts[num].label = label;
};

MyWalletPhone.isAccountNameValid = function(name) {
    if (!MyWallet.wallet.isUpgradedToHD) {
        console.log('Warning: Getting accounts when wallet has not upgraded!');
        return false;
    }

    var accounts = MyWallet.wallet.hdwallet.accounts;
    for (var i = 0; i < accounts.length; i++) {
        var account = accounts[i];
        if (account.label == name) {
            return false;
        }
    }

    return true;
}

MyWalletPhone.getReceivingAddressForAccount = function(num) {
    if (!MyWallet.wallet.isUpgradedToHD) {
        console.log('Warning: Getting accounts when wallet has not upgraded!');
        return '';
    }

    return MyWallet.wallet.hdwallet.accounts[num].receiveAddress;
};

/**
 * Returns the receiving address for a given Xpub.
 * @param {string} xpub - The target HDAccount xpub. This can be a legacy or bech32 derivation.
 * @param {boolean} forceLegacy - If the derivation for the receive address should be forced to legacy (true) or the default derivation should be used (false). [V4 Wallets only]
 */
MyWalletPhone.getReceivingAddressForAccountXPub = function(xpub, forceLegacy) {
    if (!MyWallet.wallet.isUpgradedToHD) {
        console.log('Warning: Getting accounts when wallet has not upgraded!');
        return '';
    }
    const hdwallet = MyWallet.wallet.hdwallet;
    if (hdwallet.isUpgradedToV4) {
        // V4 Wallet
        // Find the HDAccount that contains the given XPub in any of its derivations.
        var hdAccount = hdwallet.accounts.find(account => account.derivations.find(derivation => derivation.xpub == xpub));
        if (forceLegacy) {
            // Returns legacy derivation receive address.
            return hdAccount.legacyDerivationReceiveAddress;
        } else {
            // Returns default derivation receive address.
            return hdAccount.receiveAddress;
        }
    } else {
        // V3 Wallet
        return hdwallet.accounts.find(account => account.extendedPublicKey == xpub).receiveAddress;
    }
};

MyWalletPhone.isArchived = function(accountOrAddress) {
    if (Helpers.isNumber(accountOrAddress) && accountOrAddress >= 0) {

        if (MyWallet.wallet.isUpgradedToHD) {
            if (MyWallet.wallet.hdwallet.accounts[accountOrAddress] == null) {
                return_to_addresses_screen();
                return false;
            }
            return MyWallet.wallet.hdwallet.accounts[accountOrAddress].archived;
        } else {
            console.log('Warning: Getting accounts when wallet has not upgraded!');
            return false;
        }
    } else if (accountOrAddress) {

        if (MyWallet.wallet.key(accountOrAddress) == null) {
            return_to_addresses_screen();
            return false;
        }

        return MyWallet.wallet.key(accountOrAddress).archived;
    }

    return false;
}

MyWalletPhone.toggleArchived = function(accountOrAddress) {

    var didArchive = false;

    if (Helpers.isNumber(accountOrAddress) && accountOrAddress >= 0) {
        if (MyWallet.wallet.isUpgradedToHD) {
            MyWallet.wallet.hdwallet.accounts[accountOrAddress].archived = !MyWallet.wallet.hdwallet.accounts[accountOrAddress].archived;
            didArchive = MyWallet.wallet.hdwallet.accounts[accountOrAddress].archived
        } else {
            console.log('Warning: Getting accounts when wallet has not upgraded!');
            return '';
        }
    } else if (accountOrAddress) {
        MyWallet.wallet.key(accountOrAddress).archived = !MyWallet.wallet.key(accountOrAddress).archived;
        didArchive =  MyWallet.wallet.key(accountOrAddress).archived;
    }

    if (didArchive) {
        MyWalletPhone.get_history();
    }

    objc_did_archive_or_unarchive();
}

MyWalletPhone.login = function(user_guid, shared_key, resend_code, inputedPassword, sessionToken, twoFACode, twoFAType, success, needs_two_factor_code, wrong_two_factor_code, other_error) {

    // Timing
    var t0 = new Date().getTime(), t1;

    var logTime = function(name) {
        t1 = new Date().getTime();

        console.log('----------');
        console.log('Execution time ' + name + ': ' + (t1 - t0) + ' milliseconds.')
        console.log('----------');

        t0 = t1;
    };

    var fetch_success = function() {

        logTime('download');
        objc_loading_start_decrypt_wallet();
    };

    var decrypt_success = function() {
        logTime('decrypt');

        objc_did_decrypt();

        objc_loading_start_build_wallet();
    };

    var build_hd_success = function() {
        logTime('build HD wallet');

        objc_loading_start_multiaddr();
    };

    var login_success = function() {
        logTime('fetch history, account info');

        objc_did_load_wallet();
    };

    var history_error = function(error) {console.log(error);
        console.log('login: error getting history');
        objc_on_error_get_history(error);
        return Promise.reject('history_error');
    }

    var success = function() {
        logTime('wallet login');
        var fetchAccount = MyWallet.wallet.fetchAccountInfo().catch(other_error);
        Promise.all([fetchAccount]).then(login_success);
    };

    var other_error = function(e) {
        console.log('MyWalletPhone.login: other_error: error ' + e + ' stack ' + e.stack);
        objc_loading_stop();
        objc_error_other_decrypting_wallet(e, e.stack);
        return Promise.reject(e);
    };

    var needs_two_factor_code = function(type) {
        console.log('login: needs 2fa of type: ' + WalletStore.get2FATypeString());
        objc_loading_stop();
        objc_on_fetch_needs_two_factor_code();
    };

    var wrong_two_factor_code = function(error) {
        console.log('wrong two factor code: ' + error);
        objc_loading_stop();
        objc_wrong_two_factor_code(error);
    }

    var authorization_required = function() {
        console.log('authorization required');
        objc_loading_stop();
        objc_email_authorization_required();
    }

    objc_loading_start_download_wallet();

    var credentials = {};

    credentials.twoFactor = twoFACode ? {type: WalletStore.get2FAType(), code : twoFACode} : null;

    if (shared_key) {
        console.log('setting sharedKey');
        credentials.sharedKey = shared_key;
    }

    if (sessionToken) {
        console.log('setting sessionToken');
        credentials.sessionToken = sessionToken;
    }

    var callbacks = {
        needsTwoFactorCode: needs_two_factor_code,
        wrongTwoFactorCode: wrong_two_factor_code,
        authorizationRequired: authorization_required,
        didFetch: fetch_success,
        didDecrypt: decrypt_success,
        didBuildHD: build_hd_success
    }

    walletOptions.fetch().then(function() {
        MyWallet.login(user_guid, inputedPassword, credentials, callbacks).then(success).catch(other_error);
    });
};

MyWalletPhone.loginAfterPairing = function(password) {

    var other_error = function(e) {
        objc_loading_stop();
        console.log('MyWalletPhone.loginAfterPairing: other_error: error ' + e + ' stack ' + e.stack);
        objc_error_other_decrypting_wallet(e, e.stack);
        return Promise.reject(e);
    };

    var decrypt_success = function() {
        objc_did_decrypt();
        objc_loading_start_build_wallet();
    };

    var build_hd_success = function() {
        objc_loading_start_multiaddr();
    };

    var history_error = function(error) {console.log(error);
        objc_on_error_get_history(error);
        return Promise.reject('history_error');
    };

    var login_success = function() {
        objc_did_load_wallet();
    };

    var success = function() {
        var getOptions = walletOptions.fetch();
        var fetchAccount = MyWallet.wallet.fetchAccountInfo();
        Promise.all([getOptions, fetchAccount]).then(login_success);
    };

    return MyWallet.initializeWallet(password, decrypt_success, build_hd_success)
        .then(success)
        .catch(other_error);
};

MyWalletPhone.changeLastUsedReceiveIndexOfDefaultAccount = function() {
    MyWallet.wallet.hdwallet.defaultAccount.lastUsedReceiveIndex = MyWallet.wallet.hdwallet.defaultAccount.receiveIndex;
}

MyWalletPhone.sendBitcoinPayment = function(payment, secondPassword, success, error, dismiss) {
    if (MyWallet.wallet.isDoubleEncrypted) {
        if (secondPassword) {
            payment
            .sign(secondPassword)
            .publish()
            .then(success)
            .catch(error);
        } else {
            MyWalletPhone.getSecondPassword(function (pw) {
              secondPassword = pw;
              payment
              .sign(pw)
              .publish()
              .then(success).catch(error);
            }, dismiss);
        }
    } else {
        payment
        .sign()
        .publish()
        .then(success)
        .catch(error);
    }
}

MyWalletPhone.newAccount = function(password, email, firstAccountName) {
    var success = function(guid, sharedKey, password) {
        objc_loading_stop();

        objc_on_create_new_account_sharedKey_password(guid, sharedKey, password);
    };

    var error = function(e) {
        objc_loading_stop();
        var message = e;
        if (e.initial_error) {
            message = e.initial_error;
        }
        objc_on_error_creating_new_account(''+message);
    };

    MyWallet.createNewWallet(email, password, firstAccountName, null, null, success, error);
};

MyWalletPhone.setSyncPubKeys = function(syncPubKeys) {
    MyWallet.setSyncPubKeys(syncPubKeys);
};

MyWalletPhone.setLanguage = function(language) {
    MyWallet.setLanguage(language);
};

MyWalletPhone.setEncryptedWalletData = function(payload) {
    MyWallet.setEncryptedWalletData(payload);
};

MyWalletPhone.get_history = function(hideBusyView) {
    var success = function () {
        console.log('Got wallet history');
        objc_on_get_history_success();
    };

    var error = function () {
        console.log('Error getting wallet history');
        objc_loading_stop();
    };

    if (!hideBusyView) objc_loading_start_get_history();

    var getHistory = MyWallet.wallet.getHistory();
    getHistory.then(success).catch(error);
};

MyWalletPhone.markMnemonicAsVerified = function() {
  return MyWallet.wallet.hdwallet.verifyMnemonic(objc_wallet_mnemonic_verification_updated, objc_wallet_mnemonic_verification_error)
};

MyWalletPhone.getMnemonicPhrase = function(secondPassword) {
    return MyWallet.wallet.getMnemonic(secondPassword);
};

// Get passwords

MyWalletPhone.getPrivateKeyPassword = function(callback) {
    objc_get_private_key_password(function(pw) {
        callback(pw);
    });
};

MyWalletPhone.getSecondPassword = function(callback, dismiss, helperText) {
    objc_get_second_password(function(pw) {
        callback(pw);
    }, dismiss, helperText);
};

// Settings

MyWalletPhone.getAccountInfo = function () {

    var success = function (data) {
        console.log('Getting account info');
        var accountInfo = JSON.stringify(data, null, 2);
        objc_on_get_account_info_success(accountInfo);
        return data;
    }

    var error = function (e) {
        console.log('Error getting account info: ' + e);
    };

    return MyWallet.wallet.fetchAccountInfo().then(success).catch(error);
}

MyWalletPhone.getAccountInfoAndExchangeRates = function() {

    var success = function() {
        objc_on_get_account_info_and_exchange_rates()
    };

    MyWalletPhone.getAccountInfo().then(function(data) {
        var getBtcExchangeRates = MyWalletPhone.getBtcExchangeRates()
        var getBchExchangeRates = MyWalletPhone.bch.fetchExchangeRates()
        Promise.all([getBtcExchangeRates, getBchExchangeRates]).then(success);
    });
}

MyWalletPhone.changePassword = function(password) {

    var success = function () {
        console.log('Changing password');
        objc_on_change_password_success();
    };

    var error = function (e) {
        console.log('Error Changing password: ' + e);
        objc_on_change_password_error();
    };

    WalletStore.changePassword(password, success, error);
}

MyWalletPhone.changeLocalCurrency = function(code) {

    var success = function () {
        console.log('Changing local currency');
        objc_on_change_local_currency_success();
    };

    var error = function (e) {
        console.log('Error changing local currency: ' + e);
    };

    BlockchainSettingsAPI.changeLocalCurrency(code, success, error);
}

MyWalletPhone.getBtcExchangeRates = function () {

    var success = function (data) {
        console.log('Getting btc exchange rates');
        var currencySymbolData = JSON.stringify(data, null, 2);
        objc_on_get_btc_exchange_rates_success(currencySymbolData);
        return data;
    };

    var error = function (e) {
        console.log('Error getting all currency symbols: ' + e);
    };

    var promise = BlockchainAPI.getTicker();
    return promise.then(success, error);
}

MyWalletPhone.getPasswordStrength = function(password) {
    var strength = Helpers.scorePassword(password);
    return strength;
}

MyWalletPhone.checkIfWalletHasAddress = function(address) {
    return (MyWallet.wallet.addresses.indexOf(address) > -1);
}

MyWalletPhone.recoverWithPassphrase = function(email, password, passphrase) {

    if (Helpers.isValidBIP39Mnemonic(passphrase)) {
        console.log('recovering wallet');

        var accountProgress = function(obj) {
            var totalReceived = obj['total_received'];
            var finalBalance = obj['final_balance'];
            objc_on_progress_recover_with_passphrase(totalReceived, finalBalance);
        }

        var generateUUIDProgress = function() {
            objc_loading_start_generate_uuids();
        }

        var decryptWalletProgress = function() {
            objc_loading_start_decrypt_wallet();
        }

        var startedRestoreHDWallet = function() {
            objc_loading_start_recover_wallet();
        }

        var success = function (recoveredWalletDictionary) {
            console.log('recovery success');
            objc_on_success_recover_with_passphrase(recoveredWalletDictionary);
        }

        var error = function(error) {
            console.log('recovery error after validation: ' + error);
            objc_on_error_recover_with_passphrase(error);
        }

        MyWallet.recoverFromMnemonic(email, password, passphrase, '', success, error, startedRestoreHDWallet, accountProgress, generateUUIDProgress, decryptWalletProgress);

    } else {
        console.log('Invalid passphrase');
        objc_on_error_recover_with_passphrase('invalid passphrase');
    };
}

MyWalletPhone.recoverWithMetadata = function(passphrase) {

    if (Helpers.isValidBIP39Mnemonic(passphrase)) {
        console.log('recovering wallet');

        var accountProgress = function(obj) {
            var totalReceived = obj['total_received'];
            var finalBalance = obj['final_balance'];
            objc_on_progress_recover_with_metadata(totalReceived, finalBalance);
        }

        var generateUUIDProgress = function() {
            objc_loading_start_generate_uuids();
        }

        var decryptWalletProgress = function() {
            objc_loading_start_decrypt_wallet();
        }

        var startedRestoreHDWallet = function() {
            objc_loading_start_recover_wallet();
        }

        var success = function (recoveredWalletDictionary) {
            console.log('recovery success');
            objc_on_success_recover_with_passphrase(recoveredWalletDictionary);
        }

        var error = function(error) {
            console.log('recovery error after validation: ' + error);
            objc_on_error_recover_with_passphrase(error);
        }

        MyWallet.recoverFromMetadata(passphrase, success, error, startedRestoreHDWallet, accountProgress, generateUUIDProgress, decryptWalletProgress);
    } else {
        console.log('Invalid passphrase');
        objc_on_error_recover_with_passphrase('invalid passphrase');
    };
}

MyWalletPhone.setLabelForAddress = function(address, label) {
    if (label == '') {
        label = null;
    }
    MyWallet.wallet.key(address).label = label;
}

MyWalletPhone.updateServerURL = function(url) {
    console.log('Changing wallet server URL to ' + url);
    if (url.substring(url.length - 1) == '/') {
        BlockchainAPI.ROOT_URL = url;
    } else {
        BlockchainAPI.ROOT_URL = url.concat('/');
    }
}

MyWalletPhone.updateAPIURL = function(url) {
    console.log('Changing API URL to ' + url);
    if (url.substring(url.length - 1) != '/') {
        BlockchainAPI.API_ROOT_URL = url.concat('/')
    } else {
        BlockchainAPI.API_ROOT_URL = url;
    }
}

MyWalletPhone.getXpubForAccount = function(accountIndex) {
    return MyWallet.wallet.hdwallet.accounts[accountIndex].extendedPublicKey;
}

MyWalletPhone.labelForLegacyAddress = function(key) {
    var label = MyWallet.wallet.key(key).label;
    return label == null ? '' : label;
}

MyWalletPhone.getDefaultAccountLabelledAddressesCount = function() {
    if (!MyWallet.wallet.isUpgradedToHD) {
        console.log('Warning: Getting accounts when wallet has not upgraded!');
        return 0;
    }

    return MyWallet.wallet.hdwallet.defaultAccount.getLabels().length;
}

MyWalletPhone.changeNetwork = function(newNetwork) {
    console.log('Changing network to ');
    console.log(newNetwork);
    Blockchain.constants.NETWORK = newNetwork;
}

// MARK: - Ethereum

MyWalletPhone.ethereumAccountExists = function() {
    var eth = MyWallet.wallet.eth;
    return eth && eth.defaultAccount;
};

MyWalletPhone.createEthAccountIfNeeded = function(secondPassword) {
    var eth = MyWallet.wallet.eth;
    if (eth && eth.defaultAccount) {
        return Promise.resolve();
    };
    if (!MyWallet.getIsInitialized()) {
        return Promise.reject('Failed to create account.');
    };
    if (MyWallet.wallet.isDoubleEncrypted) {
        if (secondPassword) {
            return eth.createAccount(void 0, secondPassword);
        } else {
            return Promise.reject('Failed to create account.');
        };
    } else {
        return eth.createAccount(void 0);
    };
}

MyWalletPhone.saveEtherNote = function(txHash, note) {
    MyWallet.wallet.eth.setTxNote(txHash, note);
}

MyWalletPhone.getEtherNote = function(txHash) {
    return MyWallet.wallet.eth.getTxNote(txHash);
}

MyWalletPhone.recordLastTransactionAsync = function(txHash) {
    var success = function () {
        objc_on_recordLastTransactionAsync_success();
    };
    var error = function (e) {
        console.log('Error recording last transaction')
        console.log(e);
        objc_on_recordLastTransactionAsync_error(e);
    };
    return MyWallet.wallet.eth.setLastTxAndSync(txHash)
        .then(success)
        .catch(error);
};

MyWalletPhone.getEtherAccountsAsync = function (secondPassword) {
    var fetchAccounts = function () {
        var eth = MyWallet.wallet.eth;
        var accounts = [
            eth.defaultAccount.toJSON()
        ];
        return Promise.resolve(accounts);
    };
    var success = function (accounts) {
        objc_on_didGetEtherAccountsAsync(accounts);
    };
    var error = function (e) {
        console.log('Error fetching accounts')
        console.log(e);
        objc_on_error_gettingEtherAccountsAsync(e);
    };
    MyWalletPhone.createEthAccountIfNeeded(secondPassword)
        .then(fetchAccounts)
        .then(success)
        .catch(error);
};

MyWalletPhone.KYC = {
    updateUserCredentials: function(userId, lifetimeToken) {
        MyWallet.wallet.retailCore.updateUserCredentials(
            {userId: userId, lifetimeToken: lifetimeToken},
            objc_updateUserCredentials_success,
            objc_updateUserCredentials_error
        )
    },

    userId: function() {
        return MyWallet.wallet.retailCore.userId;
    },

    lifetimeToken: function() {
        return MyWallet.wallet.retailCore.lifetimeToken;
    }
}

MyWalletPhone.walletConnect = {

    /**
     * Updates the wallet connect metadata entry with the given v1 sessions.
     * @param {string} json - The JSON string of the V1 sessions array.
     */
    updateV1Sessions: function(json) {
        const walletConnect = MyWallet.wallet.walletConnect;
        const v1Sessions = JSON.parse(json);
        walletConnect.updatev1Sessions(
            v1Sessions,
            objc_updateWalletConnect_success,
            objc_updateWalletConnect_error
        )
    },

    /**
     * Returns JSON string of the V1 sessions stored in the Wallet Connect metadata entry.
     */
    v1Sessions: function() {
        const walletConnect = MyWallet.wallet.walletConnect;
        const sessions = walletConnect.v1Sessions;
        return sessions ? JSON.stringify(sessions) : null;
    }
}

MyWalletPhone.xlm = {
    saveAccount: function(publicKey, label) {
        let error = function (e) {
            console.log('Error MyWalletPhone.xlm.saveAccount')
            console.log(e)
            objc_xlmSaveAccount_error(e)
        };
        let success = function () {
            console.log('Success MyWalletPhone.xlm.saveAccount')
            objc_xlmSaveAccount_success()
        };
        MyWallet.wallet.xlm.saveAccount(
          publicKey,
          label,
          success,
          error
        );
    },

    accounts: function() {
        return MyWallet.wallet.xlm.accounts.map(function(account) {
          return account.toJSON();
        });
    }
}

MyWalletPhone.getBitcoinNote = function(txHash) {
    return MyWallet.wallet._tx_notes[txHash];
}

MyWalletPhone.getDefaultBitcoinWalletIndexAsync = function (secondPassword) {
    var getDefaultBitcoinWalletIndex = function () {
        var defaultWalletIndex = MyWalletPhone.getDefaultAccountIndex();
        return Promise.resolve(defaultWalletIndex);
    };
    var success = function (defaultWalletIndex) {
        console.log('Fetched defaultWalletIndex');
        console.log(defaultWalletIndex);
        objc_on_didGetDefaultBitcoinWalletIndexAsync(defaultWalletIndex);
    };
    var error = function (e) {
        console.log('Error fetching defaultWalletIndex');
        console.log(e);
        objc_on_error_gettingDefaultBitcoinWalletIndexAsync(e);
    };
    return getDefaultBitcoinWalletIndex()
        .then(success)
        .catch(error);
};
                                    
MyWalletPhone.getBitcoinWalletIndexAsync = function (receiveAddress) {
    var getBitcoinWalletIndex = function (address) {
    var walletIndex = MyWalletPhone.getAccountIndex(address);
        return Promise.resolve(walletIndex);
    };
    var success = function (walletIndex) {
        console.log('Fetched walletIndex');
        console.log(walletIndex);
        objc_on_didGetBitcoinWalletIndexAsync(walletIndex);
    };
    var error = function (e) {
        console.log('Error fetching walletIndex');
        console.log(e);
        objc_on_error_gettingBitcoinWalletIndexAsync(e);
    };
    return getBitcoinWalletIndex(receiveAddress)
        .then(success)
        .catch(error);
};

MyWalletPhone.getHDWalletAsync = function (secondPassword) {
    var fetchHDWallet = function () {
        var hdwallet = MyWallet.wallet.hdwallet;
        var walletJSONString = JSON.stringify(hdwallet);
        return Promise.resolve(walletJSONString);
    };
    var success = function (wallet) {
        console.log('Fetched HD Wallet');
        console.log(wallet);
        objc_on_didGetHDWalletAsync(wallet);
    };
    var error = function (e) {
        console.log('Error fetching wallet');
        console.log(e);
        objc_on_error_gettingHDWalletAsync(e);
    };
    return fetchHDWallet()
        .then(success)
        .catch(error);
};

MyWalletPhone.getBitcoinWalletsAsync = function (secondPassword) {
    var fetchAccounts = function () {
        var wallet = MyWallet.wallet.hdwallet;
        var jsonAccounts = wallet.accounts.map(function(account) {
            return account.toJSON();
        });
        var accountsJSONString = JSON.stringify(jsonAccounts);
        return Promise.resolve(accountsJSONString);
    };
    var success = function (accounts) {
        objc_on_didGetBitcoinWalletsAsync(accounts);
    };
    var error = function (e) {
        console.log('Error fetching accounts');
        console.log(e);
        objc_on_error_gettingBitcoinWalletsAsync(e);
    };
    return fetchAccounts()
        .then(success)
        .catch(error);
};

MyWalletPhone.getMobileMessage = function(languageCode) {
    var options = walletOptions.getValue();

    if (!options.mobile_notice || options.mobile_notice == null) return null;

    var notice = options.mobile_notice[languageCode];
    if (!notice || notice == null) return options.mobile_notice['en'];
    return notice;
}

MyWalletPhone.bch = {
    getHistory : function() {
        var success = function(promise) {
            console.log('Success fetching bch history')
            objc_on_fetch_bch_history_success();
            return promise;
        };

        var error = function(error) {
            console.log('Error fetching bch history')
            console.log(error);
            objc_on_fetch_bch_history_error(error);
        };

        return MyWallet.wallet.bch.getHistory().then(success).catch(error);
    },

    getHistoryAndRates : function() {
        var success = function(result) {
            objc_did_get_bitcoin_cash_exchange_rates(result[1], false);
            objc_on_fetch_bch_history_success();
            return result;
        }

        var error = function(e) {
            console.log('Error fetching bch history and rates')
            console.log(e);
        }

        var getBitcoinCashHistory = MyWallet.wallet.bch.getHistory();
        var getBitcoinCashExchangeRates = BlockchainAPI.getExchangeRate('USD', 'BCH');
        return Promise.all([getBitcoinCashHistory, getBitcoinCashExchangeRates]).then(success).catch(error);
    },

    fetchExchangeRates : function() {
        var success = function(result) {
            objc_did_get_bitcoin_cash_exchange_rates(result);
            return result;
        }

        var error = function(e) {
            console.log(e);
        }
        return BlockchainAPI.getExchangeRate('USD', 'BCH').then(success).catch(error);
    },

    hasAccount : function() {
        var bch = MyWallet.wallet.bch;
        return bch && bch.defaultAccount;
    },

    getAllAccountsCount : function() {
        var bch = MyWallet.wallet.bch;
        return bch.accounts.length;
    },

    getLabelForDefaultAccount : function() {
        return MyWallet.wallet.bch.defaultAccount.label;
    },
        
    getDefaultBCHAccount : function() {
        const defaultAccount = MyWallet.wallet.bch.defaultAccount;
        const account = {
            "label": defaultAccount.label,
            "xpub": defaultAccount.xpub,
            "index": defaultAccount.index,
            "archived": defaultAccount.archived
        }
        return JSON.stringify(account)
    },

    getDefaultAccountIndex : function() {
        return MyWallet.wallet.bch.defaultAccountIdx;
    },

    setDefaultAccount : function(index) {
        MyWallet.wallet.bch.defaultAccountIdx = index;
    },

    getReceivingAddressForAccount : function(index) {
        return Helpers.toBitcoinCash(MyWallet.wallet.bch.accounts[index].receiveAddress);
    },

    getReceivingAddressForAccountXPub : function(xpub) {
        const found = MyWallet.wallet.bch.accounts.find(account => account.xpub == xpub);
        return Helpers.toBitcoinCash(found.receiveAddress);
    },

    getLabelForAccount : function(index) {
        return MyWallet.wallet.bch.accounts[index].label;
    },

    setLabelForAccount : function(num, label) {
        MyWallet.wallet.bch.accounts[num].label = label;
    },

    getIndexOfActiveAccount : function(index) {
        var activeAccounts = MyWallet.wallet.bch.activeAccounts;
        var realNum = activeAccounts[index].index;
        return realNum;
    },

    getActiveAccountsCount : function() {
        return MyWallet.wallet.bch.activeAccounts.length;
    },

    getActiveLegacyAddresses : function() {
        if (!MyWallet.wallet || !MyWallet.wallet.bch || !MyWallet.wallet.bch.importedAddresses) {
            return [];
        }
        return MyWallet.wallet.bch.importedAddresses.addresses.map(function(address) {
            var prefix = 'bitcoincash:';
            return Helpers.toBitcoinCash(address).slice(prefix.length);
        });
    },

    getAllAccounts : function() {
        const accounts = MyWallet.wallet.bch.accounts.map(function(account) {
            return {
                "label": account.label,
                "xpub": account.xpub,
                "index": account.index,
                "archived": account.archived
            };
        });
        return JSON.stringify(accounts)
    },

    isArchived : function(index) {
        return MyWallet.wallet.bch.accounts[index].archived;
    },

    toggleArchived : function(index) {
        var account = MyWallet.wallet.bch.accounts[index];
        account.archived = !account.archived;
    },

    balanceActiveLegacy : function() {
        return MyWallet.wallet.bch.importedAddresses.balance;
    },

    getBalance : function() {
        return MyWallet.wallet.bch.balance;
    },

    getBalanceForAccount : function(index) {
        return MyWallet.wallet.bch.accounts[index].balance;
    },

    hasLegacyAddresses : function() {
        if (MyWallet.wallet.bch.importedAddresses) {
            return true;
        } else {
            return false;
        }
    },

    getBalanceForAddress : function(address) {
        return MyWallet.wallet.bch.getAddressBalance(Helpers.fromBitcoinCash('bitcoincash:' + address));
    },

    getXpubForAccount : function(index) {
        return MyWallet.wallet.bch.accounts[index].xpub;
    },

    isValidAddress : function(address) {
        var base = 'bitcoincash:';
        var prefixed = address.includes(base);
        if (!prefixed) address = base + address;
        return Helpers.fromBitcoinCash(address);
    },

    // Payment

    changePaymentToAddress : function(to) {
        console.log('Changing bch payment to address');
        if (Helpers.isBitcoinAddress(to)) {
            currentBitcoinCashPayment.to(to);
        } else {
            let base = 'bitcoincash:';
            let prefixed = to.includes(base);
            let toArg = prefixed ? to : (base + to);
            currentBitcoinCashPayment.to(Helpers.fromBitcoinCash(toArg));
        }
    },

    fromBitcoinCash : function(address) {
        var base = 'bitcoincash:';
        var prefixed = address.includes(base);
        if (!prefixed) address = base + address;
        return Helpers.fromBitcoinCash(address);
    },

    toBitcoinCash : function(address) {
        return Helpers.toBitcoinCash(address);
    }
};

MyWalletPhone.loadMetadata = function() {
    MyWallet.wallet.loadMetadata().then(function() {
        objc_reload();
    });
}

MyWalletPhone.getHistoryForAllAssets = function() {
    var walletHistory = MyWallet.wallet.getHistory();
    var bitcoinHistory = MyWallet.wallet.btc.getHistory();
    var bitcoinCashHistory = MyWallet.wallet.bch.getHistory();
    return Promise.all([walletHistory, bitcoinHistory, bitcoinCashHistory]);
}

MyWalletPhone.tradeExecution = {
    bitcoin: {
        /**
         * Signs currentPayment and then call 'objc_on_btc_tx_signed' with signed raw transaction and its vSize (formatted '<raxTx>,<vSize>').
         */
        signPayment: function (secondPassword) {
            const isV4 = MyWallet.wallet.hdwallet.accounts[0].derivations
            if (isV4) {
                currentPayment
                    .build()
                    .sign()
                Promise.all([currentPayment._payment])
                    .then(function (payment) {
                        let value = payment[0]
                        let rawTx = value.rawTx
                        let vSize = value.vSize
                        objc_on_btc_tx_signed(rawTx + ',' + vSize)
                    })
                    .catch(function(e) {
                        objc_on_btc_tx_signed_error(JSON.stringify(e))
                    })
            } else {
                return;
            }
        },
        createPayment: function (from, to, amount, feePerByte) {
            const isV4 = MyWallet.wallet.hdwallet.accounts[0].derivations
            if (isV4) {
                let btcAccount = MyWallet.wallet.btc.accounts[from];
                currentPayment = btcAccount.createPayment().to(to).amount(amount).feePerByte(feePerByte).build()

                Promise.all([currentPayment._payment, btcAccount.getAvailableBalance(feePerByte)])
                    .then(function (values) {
                        let payment = values[0]
                        let balance = values[1]
                        var paymentData = {
                            "finalFee": payment.selection.fee,
                            "sweepFee": balance.sweepFee,
                            "sweepAmount": balance.amount
                        };
                        var payload = { "payment": paymentData };
                        objc_on_create_order_payment_success(JSON.stringify(payload));
                    }).catch(function (e) {
                        var payload = { "error": JSON.stringify(e) };
                        objc_on_create_order_payment_error(JSON.stringify(payload))
                    });
            } else { 
                return;
            }
        },
        send: function (secondPassword) {
            var success = function (tx) {
                objc_on_send_order_transaction_success(tx.txid)
            };
            var error = function (err) {
                objc_on_send_order_transaction_error(err)
            }
            MyWalletPhone.sendBitcoinPayment(currentPayment, secondPassword, success, error, objc_on_send_order_transaction_dismiss);
        },
    },

    bitcoinCash: {
        createPayment: function (from, to, amount, feePerByte) {
            // Currently cannot send from BCH addresses
            let bchAccount = MyWallet.wallet.bch.accounts[from];
            currentBitcoinCashPayment = bchAccount.createPayment()
            MyWalletPhone.bch.changePaymentToAddress(to);
            currentBitcoinCashPayment.amount(amount).feePerByte(feePerByte).build()

            Promise.all([currentBitcoinCashPayment._payment, bchAccount.getAvailableBalance(feePerByte)])
                .then(function (values) {
                    let payment = values[0]
                    let balance = values[1]
                    var paymentData = {
                        "finalFee": payment.selection.fee,
                        "sweepFee": balance.sweepFee,
                        "sweepAmount": balance.amount
                    };
                    var payload = { "payment": paymentData };
                    objc_on_create_order_payment_success(JSON.stringify(payload));
                }).catch(function (e) {
                    var payload = { "error": JSON.stringify(e) };
                    objc_on_create_order_payment_error(JSON.stringify(payload))
                });
        },
        send: function (secondPassword) {
            var success = function (tx) {
                objc_on_send_order_transaction_success(tx.txid)
            };
            var error = function (err) {
                objc_on_send_order_transaction_error(err)
            }
            MyWalletPhone.sendBitcoinPayment(currentBitcoinCashPayment, secondPassword, success, error, objc_on_send_order_transaction_dismiss);
        },
    }
}
