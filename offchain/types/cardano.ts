import { Constr, Data, Lovelace, PaymentKeyHash, StakeKeyHash, UTxO, WalletApi } from "@lucid-evolution/lucid";

export type Wallet = {
  name: string;
  icon: string;
  apiVersion: string;
  enable(): Promise<WalletApi>;
  isEnabled(): Promise<boolean>;
};

export const CampaignAddressSchema = Data.Object({
  pkh: Data.Bytes(),
  skh: Data.Bytes(),
});
export type CampaignAddress = Data.Static<typeof CampaignAddressSchema>;
export const CampaignAddress = CampaignAddressSchema as unknown as CampaignAddress;

export const CampaignDatumSchema = Data.Object({
  title: Data.Bytes(),
  goal: Data.Integer(),
  deadline: Data.Integer(),
  creator: CampaignAddressSchema,
  backers: Data.Map(CampaignAddressSchema, Data.Integer()),
});
export type CampaignDatum = Data.Static<typeof CampaignDatumSchema>;
export const CampaignDatum = CampaignDatumSchema as unknown as CampaignDatum;

export type CampaignUTxO = {
  campaign: CampaignDatum;
  utxo: UTxO;
};

export const CampaignRedeemerAction = {
  pledge: Data.to(new Constr(0, [])),
  finish: Data.to(new Constr(1, [])),
  cancel: Data.to(new Constr(2, [])),
};
