import { t } from "../localization";
import { dayjs } from "../modules/dayConfig";
import RLink from "./RLink";
import SumaImage from "./SumaImage";
import React from "react";
import Card from "react-bootstrap/Card";
import Stack from "react-bootstrap/Stack";
import { Link } from "react-router-dom";

export default function OfferingCard({ id, description, image, closesAt }) {
  return (
    <Card className="rounded-5 border-0">
      <Card.Body className="p-0">
        <Stack direction="horizontal" gap={3}>
          <Link to={`/food/${id}`} className="flex-shrink-0">
            <SumaImage
              image={image}
              width={100}
              h={80}
              alt={description}
              className="rounded-5"
            />
          </Link>
          <div>
            <Card.Link
              as={RLink}
              href={`/food/${id}`}
              state={{ fromIndex: true }}
              className="h6 mb-0"
            >
              {description}
            </Card.Link>
            <Card.Text className="text-secondary small">
              {t("food:available_until")} {dayjs(closesAt).format("ll")}
            </Card.Text>
          </div>
        </Stack>
      </Card.Body>
    </Card>
  );
}
