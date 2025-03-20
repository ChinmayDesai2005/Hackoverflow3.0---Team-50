import mongoose from "mongoose";
import bcrypt from "bcrypt"

const userSchema = mongoose.Schema({
    'email': {type: String, required: true, unique: true},
    'password': {type: String, required: true}
},{
    timestamps: true
})

userSchema.pre('save', async function(next){
    if(!this.isModified("password")) return next();

    this.password = await bcrypt.hash(this.password,10);
    next();
})

userSchema.methods.matchPassword = async function (password){
    return await bcrypt.compare(password,this.password)
}

export const User = mongoose.model('User',userSchema)

