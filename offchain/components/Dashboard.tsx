import { Accordion, AccordionItem } from "@nextui-org/accordion";

import { ZonedDateTime } from "@internationalized/date";

import CreatedCampaigns from "./creator/CreatedCampaigns";
import CreateCampaignButton from "./creator/CreateCampaignButton";

import AvailableCampaigns from "./backer/AvailableCampaigns";

import {
  Address,
  applyDoubleCborEncoding,
  Constr,
  credentialToAddress,
  Data,
  fromText,
  keyHashToCredential,
  LucidEvolution,
  paymentCredentialOf,
  SpendingValidator,
  stakeCredentialOf,
  TxSignBuilder,
  UTxO,
  validatorToAddress,
} from "@lucid-evolution/lucid";
import { CampaignDatum, CampaignRedeemerAction } from "@/types/cardano";

const Script = {
  Spend: applyDoubleCborEncoding(
    "590dcc010100323232323232323232323225333004323232323253323300a3001300c37540042646464a66666602a00c2646464a66602060060022a66602860266ea80245400803854ccc040c01c00454ccc050c04cdd50048a8010070a99980819b874801000454ccc050c04cdd50048a80100700718089baa0081533300e30013010375400426646464646464646464646464464a666038601e002264646464646464646464646464646464a666060002056264a6660626068004264a66605c604260606ea80044c8c94ccc0c0c08cc0c8dd500089919299981919981919b8f006375c6044606a6ea803d2825115333032325333033302a30353754002264a6660686056606c6ea8c098c0dcdd51813181b9baa00a133710002026266e2400404cdd6981c981b1baa00114a06044606a6ea8c090c0d4dd50040a9998191814991980080080591299981c0008a400026644a66606c66ebcc0f0c0e4dd50011813181c9baa00613370000290010800981d00099801001181d8008a9998191980f00511919191919299981c19b8748010c0e8dd50008991929999998210010a99981d1816981e1baa002132533303f00100213253333330440010030030030031323253330420010051325333333047001006006006132325333045001008132533333304a00100900900913232533304800100b132533333304d001132533304a00100d132533333304f00100e132533304c304f0031333035004132330010010022232533304f002132533304c3375e0306078609e6ea807054ccc130cdc78080178a99982619b8700d02d1533304c3370e0140562a66609866ebc0200a454ccc130cdc4280da800899baf374c606e00a6e98ccc888c8cc004004010894ccc1540044cc158cdd80021ba80034bd6f7b630099191919299982a99baf33046375c608a60b06ea8020dd71822982c1baa0024c0103d879800013305a337600106ea001c01454ccc154cdd780400109982d19bb0008375066e0001c00400c4cc168cdd80011ba800133006006003375a60ae00660aa00460b200460ae002606e0506076660a26ea4080cc144dd480f25eb80cdc0a800a80d8a5014a029405280a5014a02606a02a26464a6666660aa002264a6666660ac00202a02a02a2646660780062600a60ac00c02c6eb4004054c140008050050050050c138004c144008c00800803c03cdd580080700700718260009826001006006006006182500098250019bad00100930470013047003375a00200c608800260880066eb8004c104004c0f4dd50010008008008008008a50303e303b37540022940c0f4c0f8008dd5981e000981e001181d000981b1baa00114a22a660669201196d7573745f726573656e645f646174756d203f2046616c73650014a02a660669217e6578706563742031203d0a202020206c6973742e636f756e74280a2020202020206f7574707574732c0a202020202020666e284f7574707574207b20616464726573732c202e2e207d3a204f757470757429207b2061646472657373203d3d2063616d706169676e5f7574786f2e61646472657373207d2c0a2020202029001615330334913e6578706563742076616c69646974795f72616e6765207c3e20696e74657276616c2e69735f656e746972656c795f6265666f726528646561646c696e65290016153303349120657870656374206261636b65725f706b6820213d2063726561746f722e706b6800161301b3756604660686ea8004c0d8c0dcc0ccdd5181b18199baa00115330314916d65787065637420536f6d6528496e707574207b206f75747075743a2063616d706169676e5f7574786f2c202e2e207d293a204f7074696f6e3c496e7075743e203d0a20202020696e70757473207c3e207472616e73616374696f6e2e66696e645f696e707574286f5f7265662900163301800902432325333030302330323754004264a666062604860666ea80044c064c0dcc0d0dd5000801181b18199baa002001148900302030313754606860626ea8c0d0c0d4c0c4dd5181a18189baa001153302f491ff65787065637420536f6d6528496e707574207b206f75747075743a204f7574707574207b20616464726573733a206261636b65725f616464726573732c202e2e207d2c202e2e207d29203d207b0a202020206c657420696e707574203c2d206c6973742e66696e6428696e70757473290a202020207768656e20696e7075742e6f75747075742e616464726573732e7061796d656e745f63726564656e7469616c206973207b0a202020202020566572696669636174696f6e4b657928766572696669636174696f6e5f6b65795f6861736829202d3e0a2020202020202020766572696669636174696f6e5f6b65795f68617368203d3d206261636b65725f1e706b680a2020202020205f202d3e2046616c73650a202020207d0a20207d00163301b007232533302f302230313754002266e3cdd7181a98191baa00100314a0603c60626ea8c078c0c4dd5181018189baa00102c375c60640026eb0c0c4c0c8008c0c0004c0c0c0c0c0c0c0c0c0c0008dd61817000981718170011bac302c001302837540406eacc0a8c0ac008c0a4004c0a4008dd6981380098138011bad30250013025002375c6046002603e6ea800854ccc070c04c0044c8c8c8c94ccc0814ccc080cc01cdd61813181398139813981398139813981398138011bae301030233754604c604e604e008294454cc085241416d7573745f62655f7369676e65645f62792865787472615f7369676e61746f726965732c207369676e65723a2063726561746f722e706b6829203f2046616c73650014a02a66604064a666042602860466ea80044cdc480218059bab3027302830243754604e605060486ea8c09cc090dd50008a998112498065787065637420536f6d6528496e707574207b206f75747075743a204f7574707574207b2076616c75652c202e2e207d2c202e2e207d293a204f7074696f6e3c496e7075743e203d0a202020207472616e73616374696f6e5f696e70757473207c3e207472616e73616374696f6e2e66696e645f696e707574286f5f7265662900163300900101514a22a6604292012c6d7573745f72656163685f676f616c28696e707574732c206f5f7265662c20676f616c29203f2046616c73650014a02940dd6181280098109baa019375a60460026046603e6ea80084c8c8c8c94ccc0814ccc080cc01cdd618131813981398139813981398138011bae301030233754604c008294454cc085241416d7573745f62655f7369676e65645f62792865787472615f7369676e61746f726965732c207369676e65723a2063726561746f722e706b6829203f2046616c73650014a02a666040646600200200844a66604c00229444c94ccc08cc8c8c8cc04801c8c8c94ccc0a4cdc79808980c98161baa302f002375c603260586ea80144cdc398098008020a503756605c605e00260546ea8004dd69814001181300098148010998018018008a50302900114a22a660429201296d7573745f726566756e645f616c6c286f7574707574732c206261636b65727329203f2046616c73650014a02940dd618128009812981298109baa019375660466048002604660466046603e6ea8008c074dd500a1119198008008019129998108008a50132533301e3371e6eb8c09000801052889980180180098120009299980c9806180d9baa0011375c603e60386ea80044dd7180f980e1baa001223300700223375e6014603a6ea80040088c94ccc060c03cc068dd50008a400026eb4c078c06cdd500099299980c1807980d1baa00114c103d87a8000132330010013756603e60386ea8008894ccc078004530103d87a8000132323232533301e33722911000021533301e3371e9101000021300d33023375000297ae014c0103d87a8000133006006003375a60400066eb8c078008c088008c080004c8cc004004008894ccc0740045300103d87a8000132323232533301d33722911000021533301d3371e9101000021300c33022374c00297ae014c0103d87a80001330060060033756603e0066eb8c074008c084008c07c0048c8cc004004008894ccc07000452f5bded8c026644646600200200644a66604000226604200697adef6c6013232533301e3375e6601e6eb8c038c084dd518100029bae300e30213754604000498103d8798000133023005003133023002330040040013024002302200133002002301f001301e00122323300100100322533301c00114a0264a6660326008603e00429444cc00c00c004c07c0048894ccc058c024c060dd5001899299980d800801099299999981000080180180180189919299980f0008028992999999811800803003003003099299981018118018a8040039bae00130200013020003375c002603a00260326ea800c00488c8cc00400400c894ccc068004530103d87a80001323253330183005002130073301d0024bd70099802002000980f001180e0009ba5480008c05c004894ccc044cdc80010008a60103d8798000153330113371e0040022980103d87a800014c103d87b80002301530160013014301137540042944dc3a4000016016016016602460260046022002601a6ea8008dc3a40042c601c601e004601a002601a0046016002600e6ea800452615330054911856616c696461746f722072657475726e65642066616c73650013656153300349011f72656465656d657220616374696f6e3a2052656465656d6572416374696f6e001615330024913d657870656374205b6261636b65725f706b685d3a204c6973743c5061796d656e744b6579486173683e203d2065787472615f7369676e61746f7269657300165734ae7155ceaab9e5573eae815d0aba257481"
  ),
};
const spendingValidator: SpendingValidator = {
  type: "PlutusV3",
  script: Script.Spend,
};

export default function Dashboard(props: {
  lucid: LucidEvolution;
  address: Address;
  setActionResult: (result: string) => void;
  onError: (error: any) => void;
}) {
  const { lucid, address, setActionResult, onError } = props;

  const crowdfundingAddress = validatorToAddress(lucid.config().network, spendingValidator);

  async function submitTx(tx: TxSignBuilder) {
    const txSigned = await tx.sign.withWallet().complete();
    const txHash = await txSigned.submit();

    return txHash;
  }

  type Action = (params: any) => Promise<void>;
  type ActionGroup = Record<string, Action>;

  const actions: Record<string, ActionGroup> = {
    CampaignCreator: {
      createCampaign: async (campaign: { title: string; goal: string; deadline: ZonedDateTime }) => {
        try {
          const pkh = paymentCredentialOf(address).hash;

          const stakeAddress = await lucid.wallet().rewardAddress();
          const skh = stakeAddress ? stakeCredentialOf(stakeAddress).hash : "";

          const datum: CampaignDatum = {
            title: fromText(campaign.title),
            goal: BigInt(parseFloat(campaign.goal) * 1_000000),
            deadline: BigInt(campaign.deadline.toDate().getTime()),
            creator: { pkh, skh },
            backers: new Map(),
          };

          const tx = await lucid
            .newTx()
            .pay.ToContract(crowdfundingAddress, { kind: "inline", value: Data.to(datum, CampaignDatum) })
            .complete();

          submitTx(tx).then(setActionResult).catch(onError);
        } catch (error) {
          onError(error);
        }
      },

      finishCampaign: async ({ utxo }: { utxo: UTxO }) => {
        try {
          const tx = await lucid
            .newTx()
            .collectFrom([utxo], CampaignRedeemerAction.finish)
            .attach.SpendingValidator(spendingValidator)
            .addSigner(address)
            .complete();

          submitTx(tx).then(setActionResult).catch(onError);
        } catch (error) {
          onError(error);
        }
      },

      cancelCampaign: async ({ campaign, utxo }: { campaign: CampaignDatum; utxo: UTxO }) => {
        try {
          let newTx = lucid.newTx().collectFrom([utxo], CampaignRedeemerAction.cancel).attach.SpendingValidator(spendingValidator).addSigner(address);
          campaign.backers.forEach((lovelace, { pkh, skh }) => {
            const paymentCredential = keyHashToCredential(pkh);
            const stakeCredential = skh ? keyHashToCredential(skh) : undefined;
            const backerAddress = credentialToAddress(lucid.config().network, paymentCredential, stakeCredential);
            newTx = newTx.pay.ToAddress(backerAddress, { lovelace });
          });
          const tx = await newTx.complete();

          submitTx(tx).then(setActionResult).catch(onError);
        } catch (error) {
          onError(error);
        }
      },
    },

    Backer: {
      pledgeCampaign: async ({ pledgeAmount, campaign, utxo }: { pledgeAmount: string; campaign: CampaignDatum; utxo: UTxO }) => {
        try {
          const pkh = paymentCredentialOf(address).hash;

          const stakeAddress = await lucid.wallet().rewardAddress();
          const skh = stakeAddress ? stakeCredentialOf(stakeAddress).hash : "";

          const key = [...campaign.backers.keys()].find((key) => key.pkh === pkh && key.skh === skh) ?? { pkh, skh };
          const val = BigInt(parseFloat(pledgeAmount) * 1_000000);

          const datum: CampaignDatum = {
            ...campaign,
            backers: campaign.backers.set(key, (campaign.backers.get(key) ?? 0n) + val),
          };

          const tx = await lucid
            .newTx()
            .collectFrom([utxo], CampaignRedeemerAction.pledge)
            .attach.SpendingValidator(spendingValidator)
            .pay.ToContract(
              crowdfundingAddress,
              { kind: "inline", value: Data.to(datum, CampaignDatum) },
              { ...utxo.assets, lovelace: utxo.assets.lovelace + val }
            )
            .addSigner(address)
            .validTo(new Date().getTime() + 3600_000)
            .complete();

          submitTx(tx).then(setActionResult).catch(onError);
        } catch (error) {
          onError(error);
        }
      },
    },
  };

  return (
    <div className="flex flex-col gap-2">
      <span>{address}</span>

      <Accordion variant="splitted">
        {/* CampaignCreator */}
        <AccordionItem key="1" aria-label="Accordion 1" title="Campaign Creator">
          <div className="flex flex-wrap gap-2 mb-2">
            <CreatedCampaigns
              lucid={lucid}
              address={address}
              crowdfundingAddress={crowdfundingAddress}
              finishCampaign={actions.CampaignCreator.finishCampaign}
              cancelCampaign={actions.CampaignCreator.cancelCampaign}
              onError={onError}
            />
            <CreateCampaignButton createCampaign={actions.CampaignCreator.createCampaign} onError={onError} />
          </div>
        </AccordionItem>

        {/* Backer */}
        <AccordionItem key="2" aria-label="Accordion 2" title="Pledge Campaigns">
          <div className="flex flex-wrap gap-2 mb-2">
            <AvailableCampaigns
              lucid={lucid}
              address={address}
              crowdfundingAddress={crowdfundingAddress}
              pledgeCampaign={actions.Backer.pledgeCampaign}
              onError={onError}
            />
          </div>
        </AccordionItem>
      </Accordion>
    </div>
  );
}