export interface LoginForm {
  email: string;
  password: string;
}

export interface LoginViewResult {
  message: string;
  redirectTo: string;
}
