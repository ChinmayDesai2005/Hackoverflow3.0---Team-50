import mongoose from 'mongoose';

const donationSchema = new mongoose.Schema({
  serialNumber: Number,
  paymentId: String,
  userId: String,
  amount: Number,
  paymentDate: { type: Date, default: Date.now },
  blockchain: {
    transactionHash: String,
    blockNumber: Number,
    dataHash: String,
  },
}, {
  timestamps: true
});

export const Donation = mongoose.model('Donation', donationSchema);

const fundraiserSchema = new mongoose.Schema({
  title: { type: String, required: true }, // Short form
  fullForm: { type: String, required: true }, // Full form
  description: { type: String, required: true },
  logo: { type: String, required: true }, // Logo image in base64
  goal: {type: Number, required: true},
  amountCollected: {type: Number, default: 0},
  donations: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Donation' }] // Aggregated donations
}, {
  timestamps: true
});

export const Fundraiser = mongoose.model('Fundraiser', fundraiserSchema);
