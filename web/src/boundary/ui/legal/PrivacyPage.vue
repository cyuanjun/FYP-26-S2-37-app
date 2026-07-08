<script setup lang="ts">
import { RouterLink } from "vue-router";
import LegalLayout from "./LegalLayout.vue";
</script>

<template>
  <LegalLayout title="Privacy Policy" updated="12 July 2026">
    <p>
      This policy explains what information Wise Workout collects, how we use it, and the
      choices you have. It applies to the Wise Workout mobile app and this website.
    </p>

    <h2>1. Information we collect</h2>
    <ul>
      <li><strong>Account details</strong> — your name, username, email, and role (free, premium, expert, or admin).</li>
      <li><strong>Fitness data</strong> — workouts you record or log, including duration, distance, calories, GPS location during a tracked session, and heart-rate readings from paired Bluetooth devices.</li>
      <li><strong>Profile &amp; goals</strong> — optional body metrics, fitness goals, and preferences used to personalise plans and analytics.</li>
      <li><strong>Usage</strong> — activity needed to run features such as social posts, challenges, expert requests, and notifications.</li>
    </ul>

    <h2>2. How we use your information</h2>
    <p>
      We use your data to provide the core service — recording and analysing workouts,
      generating AI-assisted progress summaries and plan suggestions, powering the social
      feed and challenges, and connecting you with experts you choose to contact.
    </p>

    <h2>3. AI processing</h2>
    <p>
      Progress summaries and plan suggestions are produced by an AI model via a secure
      server function. Output is clearly labelled as AI-assisted and is for general fitness
      guidance only — it is never medical advice.
    </p>

    <h2>4. Sharing and visibility</h2>
    <ul>
      <li>Social sharing is opt-in — a workout is private until you choose to share it.</li>
      <li><strong>Workout notes are always private</strong> and are never shown to other users.</li>
      <li>Experts only see the details of a service request you send them.</li>
      <li>We do not sell your personal data.</li>
    </ul>

    <h2>5. Storage and security</h2>
    <p>
      Data is stored in a managed PostgreSQL database (Supabase) protected by row-level
      security, so each account can only access its own records. Passwords are handled by
      the authentication provider and are never stored by us in plain text.
    </p>

    <h2>6. Your choices</h2>
    <p>
      You can view and edit your profile, control notification preferences, and request
      deletion of your account and associated data from within the app.
    </p>

    <h2>7. Not medical advice</h2>
    <p>
      Wise Workout is a fitness tool, not a medical device. Consult a qualified
      professional before starting or changing an exercise programme.
    </p>

    <h2>8. Contact</h2>
    <p>
      Questions about this policy? Use the
      <RouterLink to="/#contact">contact form on our homepage</RouterLink>.
    </p>
  </LegalLayout>
</template>
