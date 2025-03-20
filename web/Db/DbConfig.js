import {mongoose} from 'mongoose';
import {hackoverflow} from '../backend/constants.js';


async function connectDb(){
    try {
        const Connection  = await mongoose.connect(`${process.env.MONGODB_URL_LOCAL}/${hackoverflow}?authSource=admin`);
        console.log('MongoDB connected: ', Connection.connection.host); 
    } catch (error) {
        console.log('Error connecting to database: ', error);
        process.exit(1);
    }
}

export default connectDb;