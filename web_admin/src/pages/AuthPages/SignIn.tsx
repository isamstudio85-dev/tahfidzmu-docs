import PageMeta from "../../components/common/PageMeta";
import AuthLayout from "./AuthPageLayout";
import SignInFirebase from "../../components/auth/SignInFirebase";

export default function SignIn() {
  return (
    <>
      <PageMeta
        title="Masuk | Web Admin TahfidzMU"
        description="Halaman masuk Administrator Pesantren TahfidzMU."
      />
      <AuthLayout>
        <SignInFirebase />
      </AuthLayout>
    </>
  );
}
