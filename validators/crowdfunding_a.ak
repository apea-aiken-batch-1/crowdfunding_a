use cardano/transaction.{OutputReference, Transaction}
use crowdfunding
use crowdfunding/types.{CampaignDatum, RedeemerAction}

/// 1 UTxO == 1 Campaign
validator campaign {
  spend(
    datum campaign: Option<CampaignDatum>,
    redeemer action: RedeemerAction,
    o_ref: OutputReference,
    tx: Transaction,
  ) {
    when campaign is {
      Some(campaign_datum) ->
        campaign_datum
          |> crowdfunding.validate_spend_campaign(action, o_ref, tx)
      None -> True
    }
  }

  else(_) {
    fail
  }
}
