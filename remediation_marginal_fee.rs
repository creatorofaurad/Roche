pub fn calculate_marginal_fee(
    pre_mcap: u64,
    post_mcap: u64,
    lamports_in: u64,
    tier_0_threshold: u64,
    tier_0_bps: u64,
    tier_1_bps: u64,
) -> u64 {
    if pre_mcap < tier_0_threshold && post_mcap > tier_0_threshold {
        let delta_mcap_total = post_mcap.saturating_sub(pre_mcap);
        if delta_mcap_total == 0 {
            return (lamports_in as u128 * tier_0_bps as u128 / 10000) as u64;
        }
        let sub_portion_mcap = tier_0_threshold.saturating_sub(pre_mcap);
        let lamports_tier_0 = (lamports_in as u128 * sub_portion_mcap as u128 / delta_mcap_total as u128) as u64;
        let lamports_tier_1 = lamports_in.saturating_sub(lamports_tier_0);
        let fee_0 = (lamports_tier_0 as u128 * tier_0_bps as u128 / 10000) as u64;
        let fee_1 = (lamports_tier_1 as u128 * tier_1_bps as u128 / 10000) as u64;
        fee_0 + fee_1
    } else if post_mcap <= tier_0_threshold {
        ((lamports_in as u128 * tier_0_bps as u128) / 10000) as u64
    } else {
        ((lamports_in as u128 * tier_1_bps as u128) / 10000) as u64
    }
}
