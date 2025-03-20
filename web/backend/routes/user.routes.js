import { Router } from "express";
import { registerUser,loginUser, verifyOtp } from "../controllers/User.controller.js";

const routes = Router();

routes.route('/register').post(registerUser)
routes.route('/verifyotp').post(verifyOtp)
routes.route('/login').post(loginUser)

export default routes