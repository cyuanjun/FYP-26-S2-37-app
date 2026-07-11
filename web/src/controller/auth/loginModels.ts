// (#) What the login screen hands the controller: the typed email + password.
export interface LoginForm {
  email: string;
  password: string;
}

// (#) What we hand back to the view after a good login: a greeting and where to send them.
export interface LoginViewResult {
  message: string;
  redirectTo: string;
}
