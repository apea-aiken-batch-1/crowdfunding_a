import { useState } from "react";
import { Button } from "@nextui-org/button";
import { Input } from "@nextui-org/input";
import { Modal, ModalBody, ModalContent, ModalFooter, ModalHeader, useDisclosure } from "@nextui-org/modal";

import { CampaignUTxO } from "@/types/cardano";

export default function PledgeCampaignButton(props: {
  campaignUTxO: CampaignUTxO;
  pledgeCampaign: (params: any) => Promise<void>;
  onError: (error: any) => void;
}) {
  const { campaignUTxO, pledgeCampaign, onError } = props;

  const { isOpen, onOpen, onOpenChange } = useDisclosure();

  const [pledgeAmount, setPledgeAmount] = useState("0");

  return (
    <>
      <Button onPress={onOpen} className="bg-gradient-to-tr from-pink-500 to-yellow-500 text-white shadow-lg" radius="full">
        Pledge
      </Button>
      <Modal isOpen={isOpen} onOpenChange={onOpenChange} placement="top-center">
        <ModalContent>
          {(onClose) => (
            <>
              <ModalHeader className="flex flex-col gap-1">Pledge Campaign</ModalHeader>
              <ModalBody>
                <Input
                  type="number"
                  label="Goal"
                  placeholder="0.000000"
                  variant="bordered"
                  startContent={
                    <div className="pointer-events-none flex items-center">
                      <span className="text-default-400 text-small">ADA</span>
                    </div>
                  }
                  onValueChange={setPledgeAmount}
                />
              </ModalBody>
              <ModalFooter>
                <Button
                  onPress={() =>
                    pledgeCampaign({
                      ...campaignUTxO,
                      pledgeAmount,
                    })
                      .then(onClose)
                      .catch(onError)
                  }
                  className="bg-gradient-to-tr from-pink-500 to-yellow-500 text-white shadow-lg"
                  radius="full"
                >
                  Submit
                </Button>
              </ModalFooter>
            </>
          )}
        </ModalContent>
      </Modal>
    </>
  );
}
