import TODO from "../components/TODO.tsx";

export default function UnclaimedOrderList() {
  return <TODO />;
}
// export default function UnclaimedOrderList() {
//   const [claimedOrder, setClaimedOrder] = React.useState<
//     DetailedOrderHistory | Record<string, never>
//   >({});
//   const {
//     state: unclaimedOrders,
//     replaceState,
//     loading,
//     error,
//   } = useAsyncFetch<UnclaimedOrderCollection>(api.getUnclaimedOrderHistory, {
//     default: {} as UnclaimedOrderCollection,
//     pickData: true,
//   });
//
//   if (error) {
//     return (
//       <LayoutContainer top>
//         <ErrorScreen />
//       </LayoutContainer>
//     );
//   }
//   const handleOrderClaim = (o: DetailedOrderHistory) => {
//     setClaimedOrder(o);
//     replaceState({
//       ...unclaimedOrders,
//       items: unclaimedOrders.items.filter((order) => order.id !== o.id),
//     });
//   };
//   const { items } = unclaimedOrders;
//   return (
//     <>
//       <LayoutContainer gutters top>
//         <BreadcrumbBack back />
//         <PageHeading>{t("food.unclaimed_order_history_title")}</PageHeading>
//         <p>{t("food.unclaimed_order_history_intro")}</p>
//       </LayoutContainer>
//       <hr className="my-4" />
//       <ClaimedOrderModal claimedOrder={claimedOrder} onHide={() => setClaimedOrder({})} />
//       <LayoutContainer gutters>
//         {!loading ? (
//           <>
//             {!isEmpty(items) && (
//               <Stack gap={3}>
//                 {items.map((o) => (
//                   <Card key={o.id} className="p-0">
//                     <CardBody className="px-2 pb-4">
//                       <OrderDetail order={o} setOrder={(o) => handleOrderClaim(o)} />
//                     </CardBody>
//                   </Card>
//                 ))}
//               </Stack>
//             )}
//           </>
//         ) : (
//           <PageLoader />
//         )}
//       </LayoutContainer>
//       {isEmpty(items) && !loading && (
//         <>
//           <LayoutContainer gutters>
//             <p>{t("food.no_orders_to_claim")}</p>
//           </LayoutContainer>
//           <hr className="my-4" />
//           <LayoutContainer gutters>
//             <div className="button-stack">
//               <Button variant="primary" to="/order-history">
//                 <i className="bi bi-bag-check-fill me-2"></i>
//                 {t("food.order_history_title")}
//               </Button>
//             </div>
//           </LayoutContainer>
//         </>
//       )}
//     </>
//   );
// }
//
// function ClaimedOrderModal({
//   claimedOrder,
//   onHide,
// }: {
//   claimedOrder: DetailedOrderHistory | Record<string, never>;
//   onHide: () => void;
// }) {
//   return (
//     <Dialog
//       open={!isEmpty(claimedOrder)}
//       onClose={onHide}
//       labelledBy="claimed-order-modal-title"
//     >
//       <DialogHeader id="claimed-order-modal-title">
//         {t("food.order_claimed", { serial: claimedOrder.serial })}
//       </DialogHeader>
//       <div className="mt-4 d-flex justify-content-center align-items-center flex-column">
//         <ScrollTopOnMount />
//         <AnimatedCheckmark />
//         <p className="mt-2 fs-4 w-75 text-center">
//           {t("food.order_for_claimed_on", {
//             offeringDescription: claimedOrder.offeringDescription,
//             fulfilledAt: dayjs(claimedOrder.fulfilledAt).format("lll"),
//           })}
//         </p>
//         <Stack gap={3}>
//           {(claimedOrder as DetailedOrderHistory)?.items?.map(
//             ({ image, name, customerPrice, quantity }) => (
//               <Card key={name}>
//                 <CardBody>
//                   <Stack direction="horizontal" gap={3} className="align-items-start">
//                     <SumaImage
//                       image={image}
//                       width={80}
//                       height={80}
//                       className="border rounded"
//                     />
//                     <div className="text-align-start">
//                       <div className="lead">{name}</div>
//                       <Badge bg="secondary" className="fs-6">
//                         {t("food.price_times_quantity", {
//                           price: customerPrice,
//                           quantity,
//                         })}
//                       </Badge>
//                     </div>
//                   </Stack>
//                 </CardBody>
//               </Card>
//             )
//           )}
//         </Stack>
//         <div className="mt-2">
//           <FormButtons
//             primaryProps={{
//               type: "button",
//               variant: "outline",
//               children: t("common.close"),
//               onClick: () => onHide(),
//             }}
//             secondaryProps={{
//               variant: "outline",
//               children: t("food.view_order"),
//               href: `/order/${claimedOrder.id}`,
//             }}
//           />
//         </div>
//       </div>
//     </Dialog>
//   );
// }
