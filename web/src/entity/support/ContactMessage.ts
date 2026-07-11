// (#) What a visitor types into the Contact Us form before we send it off.
export interface NewContactMessage {
  submitterName: string;
  submitterEmail: string;
  message: string;
}
