import cookieParser from "cookie-parser";
import express from "express"
import cors from "cors"

const app = express();

app.use(cors({
    origin: process.env.CORS_ORIGIN,
    credentials: true
}))

// app.use(express.json({limit: '16kb'}))

app.use(express.json({limit: "200mb"}))

app.use(express.urlencoded({extended: true,limit: '100mb'}));

app.use(express.text({limit: "200mb"}))

app.use(express.static('public'));

app.use(cookieParser());

//routes
import userRoutes from './routes/user.routes.js'
import OrgUser from './OrgUser.js'

app.use("/v1/user",userRoutes)
app.use("/v1/orguser",OrgUser)


export {app}