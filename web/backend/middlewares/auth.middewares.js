import jwt from 'jsonwebtoken';
import { User } from '../models/user.models.js';

const Authentication = async(req,res,next) => {
const userId = req.cookies?.accessToken;

if(!userId){
    return res.status(400).json({message: "No token found Login again"});
}

const decodedToken = jwt.verify(userId,process.env.ACCESS_TOKEN_SECRET)
const user = await User.findById(decodedToken?.id).select("-password");

if(!user){
    console.log(user)
    return res.status(400).json({message: "Token is not valid"})
}

req.user = user;

next();
}

export {Authentication}