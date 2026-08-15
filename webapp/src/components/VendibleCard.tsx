import { t } from "../localization";
import { dayjs } from "../modules/dayConfig";
import Card from "../ui/Card";
import CardBody from "../ui/CardBody";
import CardLink from "../ui/CardLink";
import CardText from "../ui/CardText";
import Stack from "../ui/Stack";
import SumaImage from "./SumaImage";
import clsx from "clsx";
import React from "react";
import { Link } from "react-router-dom";

interface VendibleCardProps {
  description: React.ReactNode;
  image?: Image;
  closesAt?: string;
  appLink: string;
  className?: string;
}

export default function VendibleCard({
  description,
  image,
  closesAt,
  appLink,
  className,
}: VendibleCardProps) {
  return (
    <Card className={clsx(className)}>
      <CardBody className="p-2">
        <Stack direction="horizontal" gap={3}>
          <Link to={appLink} className="flex-shrink-0">
            <SumaImage image={image} width={100} h={80} variant="dark" />
          </Link>
          <div>
            <CardLink
              href={appLink}
              state={{ fromIndex: true }}
              className="h6 mb-0"
            >
              {description}
            </CardLink>
            {closesAt && (
              <CardText className="text-secondary small">
                {t("food.available_until", { date: dayjs(closesAt).format("ll") })}
              </CardText>
            )}
          </div>
        </Stack>
      </CardBody>
    </Card>
  );
}
