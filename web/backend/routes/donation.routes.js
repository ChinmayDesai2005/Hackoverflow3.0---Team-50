import { Router } from "express";
import {
  createOrder,
  verifyPayment,
  getDonations,
  createFundraiser,
  deleteFundraiser,
  getLast30DaysDonations,
  getFundraiserfromId,
  getFundraiserAnalytics
} from "../controllers/donation.controller.js";

const routes = Router();

//prefix - /v1/donation example /v1/donation/get-donations

routes.route("/create-order").post(createOrder);
routes.route("/verify-payment").post(verifyPayment);
routes.route("/get-donations").get(getDonations);
routes.route("/create-fundraiser").post(createFundraiser);
routes.route("/delete/:id").delete(deleteFundraiser);
routes.route("/get-fundraiser").get(getLast30DaysDonations);
routes.route("/get-fundraiser-from-id").get(getFundraiserfromId);
routes.route("/get-fundraiser-analytics").get(getFundraiserAnalytics);

export default routes;
