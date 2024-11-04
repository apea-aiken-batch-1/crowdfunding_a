import { useState } from "react";
import { Button } from "@nextui-org/button";
import { DatePicker } from "@nextui-org/date-picker";
import { Input } from "@nextui-org/input";
import { Modal, ModalBody, ModalContent, ModalFooter, ModalHeader, useDisclosure } from "@nextui-org/modal";

import { getLocalTimeZone, now } from "@internationalized/date";

export default function CreateCampaignButton(props: { createCampaign: (params: any) => Promise<void>; onError: (error: any) => void }) {
  const { createCampaign, onError } = props;

  const { isOpen, onOpen, onOpenChange } = useDisclosure();

  const [campaignTitle, setCampaignTitle] = useState("");
  const [campaignGoal, setCampaignGoal] = useState("0");
  const [campaignDeadline, setCampaignDeadline] = useState(now(getLocalTimeZone()));

  return (
    <>
      <Button onPress={onOpen} className="bg-gradient-to-tr from-pink-500 to-yellow-500 text-white shadow-lg" radius="full">
        Create Campaign
      </Button>
      <Modal isOpen={isOpen} onOpenChange={onOpenChange} placement="top-center">
        <ModalContent>
          {(onClose) => (
            <>
              <ModalHeader className="flex flex-col gap-1">Create Campaign</ModalHeader>
              <ModalBody>
                <Input autoFocus label="Title" placeholder="Campaign Title" variant="bordered" onValueChange={setCampaignTitle} />
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
                  onValueChange={setCampaignGoal}
                />
                <DatePicker
                  label="Deadline"
                  variant="bordered"
                  hideTimeZone
                  showMonthAndYearPickers
                  defaultValue={now(getLocalTimeZone())}
                  onChange={setCampaignDeadline}
                />
              </ModalBody>
              <ModalFooter>
                <Button
                  onPress={() =>
                    createCampaign({
                      title: campaignTitle,
                      goal: campaignGoal,
                      deadline: campaignDeadline,
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
