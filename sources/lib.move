module Test::test {
    use 0x1::signer;
    use 0x1::account::{Self, SignerCapability};
    use 0x1::coins;
    use 0x1::coin;
    use 0x1::aptos_coin::AptosCoin;

    const MY_ERROR_CODE: u64 = 0;

    struct MyCoin has key {
        
    }

    struct State has key {
        swap_market_address: address
    }

    struct SwapMarket has key {
        coin_b_num: u64,
        capability: SignerCapability
    }

    public entry fun init(admin: &signer) {
        let admin_address = signer::address_of(admin);
        assert!(admin_address == @ADMIN, MY_ERROR_CODE);

        let seed: vector<u8> = b"SwapMarket";
        let (swap_market_signer, capability) = account::create_resource_account(admin, seed);
        let swap_market_address = signer::address_of(&swap_market_signer);

        let state = State {
            swap_market_address
        };
        move_to<State>(admin, state);

        let swap_market = SwapMarket {
            coin_b_num: 0,
            capability
        };
        move_to<SwapMarket>(&swap_market_signer, swap_market);
        coins::register_internal<AptosCoin>(&swap_market_signer);
    }

    public entry fun deposit(admin: &signer, coin_b_num: u64) acquires State, SwapMarket {
        let admin_address = signer::address_of(admin);
        let state = borrow_global<State>(admin_address);
        let swap_market = borrow_global_mut<SwapMarket>(state.swap_market_address);

        coin::transfer<AptosCoin>(admin, state.swap_market_address, coin_b_num);
        swap_market.coin_b_num = swap_market.coin_b_num + coin_b_num;
    }

    public entry fun swap<CoinType>(user: &signer, coin_a_num: u64) acquires State, SwapMarket {
        let state = borrow_global<State>(@ADMIN);
        let swap_market = borrow_global_mut<SwapMarket>(state.swap_market_address);
        let user_address = signer::address_of(user);
        let swap_market_signer = account::create_signer_with_capability(&swap_market.capability);

        if (!coin::is_account_registered<CoinType>(state.swap_market_address)) {
            coins::register_internal<CoinType>(&swap_market_signer);
        };
        coin::transfer<CoinType>(user, state.swap_market_address, coin_a_num);

        if (!coin::is_account_registered<AptosCoin>(user_address)) {
            coins::register_internal<AptosCoin>(user);
        };
        coin::transfer<AptosCoin>(&swap_market_signer, user_address, coin_a_num);
    }
}