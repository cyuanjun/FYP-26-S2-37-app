<script setup lang="ts">
import { RouterLink } from "vue-router";
import LegalLayout from "./LegalLayout.vue";
</script>

<template>
  <LegalLayout title="Terms of Service" updated="12 July 2026">
    <p>
      These terms govern your use of Wise Workout. By creating an account or using the app
      or website, you agree to them.
    </p>

    <h2>1. Accounts</h2>
    <p>
      You are responsible for keeping your login secure and for activity on your account.
      Provide accurate details when you register, and keep them up to date.
    </p>

    <h2>2. Subscriptions and payments</h2>
    <p>
      Wise Workout offers a free tier and a Premium tier at $9.99/month. Expert services are
      purchased separately as add-ons and are not included in Premium. In this
      demonstration build, payments are simulated — no real charges are made and no card
      details are collected.
    </p>

    <h2>3. Expert services</h2>
    <p>
      Experts are independent providers who are verified before offering services. Wise
      Workout facilitates discovery and requests but is not a party to the coaching
      relationship and does not guarantee any specific result.
    </p>

    <h2>4. Acceptable use</h2>
    <ul>
      <li>Don't misuse the service, attempt to access other users' data, or disrupt the platform.</li>
      <li>Don't post unlawful, harmful, or infringing content to the social feed or reviews.</li>
      <li>Experts must represent their qualifications honestly.</li>
    </ul>

    <h2>5. Health disclaimer</h2>
    <p>
      Wise Workout provides fitness tracking and AI-assisted guidance for informational
      purposes only. It is not medical advice and is not a substitute for professional
      care. Consult a qualified professional before starting or changing an exercise
      programme, and stop if you feel unwell.
    </p>

    <h2>6. Content and intellectual property</h2>
    <p>
      You keep ownership of the content you create. By sharing it on the platform you grant
      us a licence to display it as part of the service. The Wise Workout name, app, and
      website remain our property.
    </p>

    <h2>7. Termination</h2>
    <p>
      You may stop using Wise Workout and delete your account at any time. We may suspend
      accounts that breach these terms.
    </p>

    <h2>8. Changes</h2>
    <p>
      We may update these terms as the service evolves. Continued use after an update means
      you accept the revised terms.
    </p>

    <h2>9. Contact</h2>
    <p>
      Questions about these terms? Use the
      <RouterLink to="/#contact">contact form on our homepage</RouterLink>.
    </p>
  </LegalLayout>
</template>
