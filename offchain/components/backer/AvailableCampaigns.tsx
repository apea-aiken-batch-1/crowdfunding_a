import { useEffect, useState } from "react";
import { Spinner } from "@nextui-org/spinner";
import { Table, TableBody, TableCell, TableColumn, TableHeader, TableRow } from "@nextui-org/table";

import PledgeCampaignButton from "./PledgeCampaignButton";

import { Address, Data, LucidEvolution, paymentCredentialOf, toText, UTxO } from "@lucid-evolution/lucid";
import { CampaignDatum, CampaignUTxO } from "@/types/cardano";

export default function AvailableCampaigns(props: {
  lucid: LucidEvolution;
  address: Address;
  crowdfundingAddress: Address;
  pledgeCampaign: (params: any) => Promise<void>;
  onError: (error: any) => void;
}) {
  const { lucid, address, crowdfundingAddress, pledgeCampaign, onError } = props;

  const [campaigns, setCampaigns] = useState<CampaignUTxO[]>();

  useEffect(() => {
    lucid.utxosAt(crowdfundingAddress).then(utxosToCampaigns).then(setCampaigns).catch(onError);
  }, []);

  async function utxosToCampaigns(utxos: UTxO[]) {
    const pkh = paymentCredentialOf(address).hash;
    const campaigns: CampaignUTxO[] = [];

    for (const utxo of utxos) {
      if (!utxo.datum) continue;
      const campaign = Data.from(utxo.datum, CampaignDatum);

      if (campaign.creator.pkh === pkh) continue;
      campaigns.push({ campaign, utxo });
    }

    return campaigns.sort((l, r) => {
      return l.campaign.deadline < r.campaign.deadline ? -1 : 1;
    });
  }

  function calcCurrentFunds(backers: Map<{ pkh: string; skh: string }, bigint>) {
    return backers.values().reduce((prev, curr) => prev + curr, 0n);
  }

  if (campaigns == undefined)
    return (
      <div className="flex justify-center w-full">
        <Spinner />
      </div>
    );

  return (
    <Table isStriped aria-label="Creator Campaigns">
      <TableHeader>
        <TableColumn className="text-center">Title</TableColumn>
        <TableColumn className="text-center">Curr</TableColumn>
        <TableColumn className="text-center">Goal</TableColumn>
        <TableColumn className="text-center">Deadline</TableColumn>
        <TableColumn className="text-center">Action</TableColumn>
      </TableHeader>
      <TableBody emptyContent={"No rows to display."}>
        {campaigns?.map(({ campaign, utxo }, c) => (
          <TableRow key={`campaign.${c}`}>
            <TableCell className="text-center">{toText(campaign.title)}</TableCell>
            <TableCell className="text-center">{`${calcCurrentFunds(campaign.backers) / 1_000000n}.${calcCurrentFunds(campaign.backers) % 1_000000n} ADA`}</TableCell>
            <TableCell className="text-center">{`${campaign.goal / 1_000000n}.${campaign.goal % 1_000000n} ADA`}</TableCell>
            <TableCell className="text-center">{new Date(parseInt(campaign.deadline.toString())).toString()}</TableCell>
            <TableCell className="text-center">
              <PledgeCampaignButton campaignUTxO={{ campaign, utxo }} pledgeCampaign={pledgeCampaign} onError={onError} />
            </TableCell>
          </TableRow>
        ))}
      </TableBody>
    </Table>
  );
}
