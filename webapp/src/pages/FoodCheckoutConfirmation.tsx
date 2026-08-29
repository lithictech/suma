import TODO from "../components/TODO.tsx";

export default function FoodCheckoutConfirmation() {
  return <TODO />;
}
//   const { user } = useUser();
//   const { id } = useParams();
//   const location = useLocation();
//   const getCheckoutConfirmation = React.useCallback(
//     () => api.getCheckoutConfirmation({ id }),
//     [id]
//   );
//   const {
//     state: checkout,
//     loading,
//     error,
//   } = useAsyncFetch<CheckoutConfirmation>(getCheckoutConfirmation, {
//     default: {} as CheckoutConfirmation,
//     pickData: true,
//     pullFromState: "checkout",
//     location,
//   });
//
//   if (error) {
//     return (
//       <LayoutContainer top>
//         <ErrorScreen />
//       </LayoutContainer>
//     );
//   }
//   if (loading) {
//     return <PageLoader buffered />;
//   }
//   const { fulfillmentOption, items, offering } = checkout;
//   return (
//     <>
//       <div className="bg-success text-white p-4">
//         <AlertHeading>{t("food.confirmation_title")}</AlertHeading>
//         <p className="mb-0">{t("food.confirmation_subtitle")}</p>
//       </div>
//       <LayoutContainer gutters top>
//         <h4 className="mb-3">{t("food.confirmation_my_order")}</h4>
//         {items.map((p, idx: number) => (
//           <Item key={idx} item={p} />
//         ))}
//         {user.unclaimedOrdersCount !== 0 && (
//           <div className="button-stack my-4">
//             <Button variant="primary" to="/unclaimed-orders">
//               {t("food.unclaimed_order_history_title")}
//             </Button>
//           </div>
//         )}
//         {offering.fulfillmentInstructions && (
//           <p className="lead">{dt(offering.fulfillmentInstructions)}</p>
//         )}
//       </LayoutContainer>
//       <hr className="my-4" />
//       {fulfillmentOption && (
//         <>
//           <LayoutContainer gutters>
//             <h4>{dt(offering.fulfillmentConfirmation)}</h4>
//             <p>{dt(fulfillmentOption.description)}</p>
//           </LayoutContainer>
//           <hr className="my-4" />
//         </>
//       )}
//       <LayoutContainer gutters>
//         <h4>{t("food.confirmation_transportation_title")}</h4>
//         <p className="mb-0">{t("food.confirmation_transportation_subtitle")}</p>
//         <div className="button-stack mt-3 mb-4">
//           <Button to="/mobility">
//             <i className="bi bi-scooter me-2"></i>
//             {t("food.mobility_options")}
//           </Button>
//         </div>
//       </LayoutContainer>
//       <hr className="my-4" />
//       <LayoutContainer gutters>{t("food.confirmation_help")}</LayoutContainer>
//     </>
//   );
// }
//
// function Item({ item }: { item: CheckoutConfirmationItem }) {
//   const { product, quantity } = item;
//   return (
//     <Stack direction="horizontal" gap={3} className="mb-3 align-items-start">
//       <SumaImage image={product.images[0]} className="rounded" width={90} height={90} />
//       <Stack>
//         <p className="mb-0 lead">{dt(product.name)}</p>
//         <p className="text-secondary mb-0">
//           {t("food.quantity", { quantity: quantity })}
//         </p>
//       </Stack>
//     </Stack>
//   );
// }
