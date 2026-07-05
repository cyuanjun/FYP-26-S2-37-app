#!/usr/bin/env python3
"""Fill the genuine content gaps in the PTD-filled doc, on a copy, preserving everything else.

MANUAL-ONLY utility (simplify L5): not part of the PTD build pipeline
(expand_ptd.py -> build_ptd_v1format.py). Run by hand for ad-hoc gap fills."""
import shutil, docx

SRC = "/Users/cyj/Downloads/FYP-26-S2-37-PTD-filled.docx"
OUT = "/Users/cyj/Downloads/FYP-26-S2-37-PTD-v2.docx"
shutil.copyfile(SRC, OUT)
doc = docx.Document(OUT)

# ---------- helpers ----------
def find_para(prefix):
    for p in doc.paragraphs:
        if p.text.strip().startswith(prefix):
            return p
    raise ValueError("anchor not found: " + prefix)

def _set_cell(cell, text):
    parts = str(text).split("\n")
    cell.text = parts[0]
    for extra in parts[1:]:
        cell.add_paragraph(extra)

def _mk_para(text="", style="Normal"):
    return doc.add_paragraph(text, style=style)

def _mk_rich(segments, style="Normal"):
    p = doc.add_paragraph(style=style)
    for text, bold in segments:
        r = p.add_run(text); r.bold = bold
    return p

def _mk_table(rows, header_bold=True):
    t = doc.add_table(rows=len(rows), cols=len(rows[0]))
    t.style = "Table Grid"
    for i, row in enumerate(rows):
        for j, val in enumerate(row):
            c = t.rows[i].cells[j]
            _set_cell(c, val)
            if header_bold and i == 0:
                for pp in c.paragraphs:
                    for rr in pp.runs:
                        rr.bold = True
    return t

def fill_after(anchor_prefix, blocks):
    """Insert blocks (in order) immediately after the anchor heading."""
    cursor = find_para(anchor_prefix)._p
    for b in blocks:
        kind = b[0]
        if kind == "p":
            el = _mk_para(b[1])._p
        elif kind == "pb":
            el = _mk_rich([(b[1], True)])._p
        elif kind == "bul":
            el = _mk_para(b[1], style="List Bullet")._p
        elif kind == "rbul":
            el = _mk_rich(b[1], style="List Bullet")._p
        elif kind == "tbl":
            el = _mk_table(b[1])._tbl
        else:
            raise ValueError(kind)
        cursor.addnext(el)
        cursor = el

# =====================================================================
# 2.1 Competitor Market Research
# =====================================================================
fill_after("2.1 Competitor", [
 ("p", "To position Wise Workout in the market, seven existing fitness applications were "
       "reviewed - Strava, MyFitnessPal, adidas Running, Google Fit, Freeletics, MapMyFitness, "
       "and Lyfta. They span the main market segments: activity tracking, nutrition tracking, "
       "AI-based fitness planning, health-data aggregation, and strength training. The full "
       "feature-by-feature comparison is given in the Product Comparison Matrix (Section 2.2); "
       "the key takeaway for each application is summarised below."),
 ("rbul", [("Strava - ", True), ("GPS tracking for running, cycling, and other endurance "
       "activities, with strong social sharing, segments, and challenges (freemium; AI summaries "
       "behind premium). It shows the value of combining tracking with community, but is "
       "endurance- and social-focused. Wise Workout differentiates by adding AI-assisted "
       "summaries plus access to verified human experts.", False)]),
 ("rbul", [("MyFitnessPal - ", True), ("nutrition and calorie tracking with food logging, "
       "barcode scanning, and wearable integration (freemium). It demonstrates the value of habit "
       "logging and dietary insight, but is food-centric rather than workout- or coaching-centric. "
       "Wise Workout focuses on exercise analytics and an expert-services layer.", False)]),
 ("rbul", [("adidas Running - ", True), ("GPS cardio tracking with structured training plans "
       "and challenges (freemium). It shows the value of goal-based plans, but is running-centric. "
       "Wise Workout supports a wider range of workout types plus paid expert services.", False)]),
 ("rbul", [("Google Fit - ", True), ("a health-data hub aggregating steps, calories, and Heart "
       "Points across devices (ecosystem-funded rather than subscription). It highlights data "
       "integration, but lacks coaching and expert guidance. Wise Workout adds AI summaries/"
       "planning and expert-led services.", False)]),
 ("rbul", [("Freeletics - ", True), ("an AI Coach delivering adaptive, personalised (mainly "
       "bodyweight) plans (subscription). It is the most relevant competitor - it proves AI "
       "planning as a premium feature. Wise Workout differentiates by pairing AI guidance with "
       "verified human experts.", False)]),
 ("rbul", [("MapMyFitness - ", True), ("GPS tracking, route mapping, audio coaching, and "
       "premium analytics within the Under Armour ecosystem (freemium). It shows detailed "
       "tracking and premium-analytics value, but is weak on AI-driven decisions and experts. "
       "Wise Workout adds smarter recommendations and an expert layer.", False)]),
 ("rbul", [("Lyfta - ", True), ("a strength-training planner with high-quality 3D exercise "
       "animations and visual form guidance (freemium). It shows the value of visual strength "
       "guidance. Wise Workout extends into broader tracking, AI summaries/planning, and expert "
       "services.", False)]),
])

# =====================================================================
# 2.4 SWOT Analysis
# =====================================================================
fill_after("2.4 SWOT", [
 ("p", "The SWOT analysis below summarises the strategic position of Wise Workout as a Final "
       "Year Project product concept."),
 ("pb", "Strengths"),
 ("bul", "Integrated platform - workout tracking, AI-assisted progress summaries, AI plan "
       "suggestions, a verified human-expert marketplace, and a social/challenge layer in one "
       "cross-platform app, instead of stitching together several single-purpose apps."),
 ("bul", "Three-layer business model - Free, Premium, and an a-la-carte expert-services layer "
       "that both Free and Premium users can buy, giving multiple revenue paths without paywalling "
       "human expertise behind Premium."),
 ("bul", "AI used responsibly - scope is deliberately limited to summaries and plan suggestions; "
       "coaching and custom plans come from verified human experts, and all AI output is labelled "
       "AI-assisted (never medical advice), reducing liability and building trust."),
 ("bul", "Modular, extensible architecture - a managed backend (Supabase) and a clean sensor "
       "abstraction mean wearables/HealthKit, BLE heart-rate, and push notifications can be added "
       "later as new modules rather than rewrites."),
 ("bul", "Disciplined engineering design - a Boundary-Control-Entity architecture with traceable "
       "use cases, sequence diagrams, and role-based plus row-level access control."),
 ("pb", "Weaknesses"),
 ("bul", "Resource and time constraints of an FYP (4-person team, two terms) limit the depth of "
       "advanced features; some capabilities (payment, wearable sync) are delivered at a simulated "
       "or conceptual level."),
 ("bul", "No existing user base or brand recognition - the platform starts from zero against "
       "established incumbents."),
 ("bul", "Dependence on third-party services (OpenAI/Gemini, Supabase) for core functionality, "
       "exposing the product to their pricing, availability, and policy changes."),
 ("bul", "Narrow initial AI capability by design - users expecting full AI coaching may perceive "
       "the summaries/suggestions as limited."),
 ("bul", "Expert marketplace needs supply - value depends on attracting verified experts, a "
       "two-sided-market cold-start challenge."),
 ("pb", "Opportunities"),
 ("bul", "Growing fitness-app and wearable market with rising demand for data-driven and "
       "AI-assisted training."),
 ("bul", "Underserved gap - few mainstream apps connect users to verified human experts inside "
       "the same app; this is the differentiator."),
 ("bul", "Regional health-tech momentum (Singapore's digital-health and preventive-health push) "
       "supports adoption."),
 ("bul", "Clear expansion paths - wearable/HealthKit integration, nutrition tracking, "
       "corporate-wellness packages, and additional expert categories."),
 ("pb", "Threats"),
 ("bul", "Strong incumbents - Strava, MyFitnessPal, adidas Running, Google Fit, Freeletics, and "
       "MapMyFitness compete on tracking, analytics, or AI plans."),
 ("bul", "Platform and SDK risk - changes to social-sharing APIs, HealthKit/Health Connect, or "
       "app-store policies can break features."),
 ("bul", "Data-privacy regulation - fitness and health data are sensitive under PDPA and "
       "app-store health-data rules (see Section 9.2)."),
 ("bul", "AI cost and policy volatility - provider price increases or usage-policy changes could "
       "affect the AI features."),
 ("bul", "User trust - scepticism toward AI guidance for health-adjacent decisions."),
])

# =====================================================================
# 2.6 Target Users
# =====================================================================
fill_after("2.6 Target", [
 ("p", "Wise Workout is designed for individuals who want a more organised way to manage their "
       "fitness activities, monitor progress, and receive guidance based on their goals. Users "
       "range from beginners who need simple workout guidance to active users who want detailed "
       "progress tracking, AI-assisted summaries, and AI-assisted plan suggestions. The main "
       "target groups are:"),
 ("bul", "Casual fitness users who want to record basic workout activities and stay active."),
 ("bul", "Beginners who need simple guidance, reminders, and progress summaries."),
 ("bul", "Regular exercisers who want to track history, monitor improvements, and understand "
       "activity patterns over time."),
 ("bul", "Goal-oriented users with specific objectives - endurance, weight loss, strength, sport "
       "preparation, or recovery."),
 ("bul", "Users who need expert support and want to discover verified professionals such as "
       "running/cycling/football coaches, strength trainers, nutritionists, and recovery "
       "specialists."),
 ("p", "The platform is also intended for verified fitness and wellness professionals who offer "
       "services through it, and for system administrators who manage the platform, verify "
       "experts, and maintain quality. These groups map to the five user categories described in "
       "Section 2.6 (Unregistered, Registered Free, Registered Premium, Expert, and System Admin)."),
])

# =====================================================================
# 3. Stakeholders
# =====================================================================
fill_after("3. Stakeholders", [
 ("p", "The stakeholders of Wise Workout are the parties with an interest in the project's "
       "delivery and outcome. They are summarised below."),
 ("tbl", [
   ["Stakeholder", "Interest / Role"],
   ["Project team (4 members)", "Design, build, test, and document the system; deliver all FYP "
       "milestones. Roles: coordination/docs, mobile/UI, backend/database/API, website/expert & "
       "admin."],
   ["Supervisor (Mr Premrajan)", "Provides guidance, reviews milestones, and signs off "
       "deliverables before submission."],
   ["Assessors / evaluators (UOW/SIM)", "Evaluate the documentation, prototype, and final "
       "demonstration against the FYP rubric."],
   ["End users (Free / Premium)", "Use the app to track workouts, view analytics, receive AI "
       "summaries and plan suggestions, and engage socially."],
   ["Verified experts", "Publish service listings and respond to user service requests through "
       "the platform."],
   ["System administrators", "Manage accounts, verify experts, moderate content, and maintain "
       "platform quality and reliability."],
   ["Third-party service providers", "Supabase (backend), OpenAI/Gemini (AI), and social "
       "platforms - external dependencies the system integrates with."],
 ]),
])

# =====================================================================
# 4.1 Data Sources
# =====================================================================
fill_after("4.1 Data Sources", [
 ("p", "Wise Workout does not rely on public datasets. Its data originates from the users and the "
       "platform itself, captured through the following sources:"),
 ("bul", "Phone sensors - GPS (geolocator) for distance, pace, and route, and the pedometer for "
       "step/cadence data during a workout session."),
 ("bul", "Wearable devices - heart-rate data via a mock-BLE pairing flow with a simulated HR "
       "stream in the prototype; the same interface accepts a real BLE/HealthKit source later."),
 ("bul", "Manual user input - registration, fitness profile, goals, manual workout entry, expert "
       "applications, service requests, and feedback."),
 ("bul", "Backend records - data stored in and retrieved from Supabase (PostgreSQL) through "
       "queries, RPCs, and row-level-security-protected views."),
 ("bul", "AI services - prompt context (profile, goal, and workout history) sent to the AI "
       "provider through Supabase Edge Functions, which return summaries and plan suggestions."),
])

# =====================================================================
# 5.1 Project Milestones
# =====================================================================
fill_after("5.1 Project Milestones", [
 ("p", "The key project deadlines and milestones are listed below. The project begins on 4 April "
       "2026, with major deliverables scheduled from April to August 2026. Each milestone "
       "represents an important checkpoint, deliverable, or demonstration requirement across "
       "Term 1 and Term 2."),
 ("tbl", [
   ["No.", "Milestone / Checkpoint", "Deadline", "Key Deliverables"],
   ["1", "Team Formation and Project Website Setup", "11 April 2026",
    "Team members confirmed\nTeam leader identified\nProject website created\nFirst reflective diary completed"],
   ["2", "Project Requirement Documentation Completion", "2 May 2026 (submission by 9 May 2026)",
    "Research summary\nWork Breakdown Structure\nUse case diagrams\nProject schedule\nDevelopment tools and methodology"],
   ["3", "System Requirement Specification Completion", "14 May 2026",
    "System services\nFunctional requirements\nNon-functional requirements\nSecurity requirements\nInterfaces and constraints"],
   ["4", "Technical Design Manual and Functional Prototype", "21 May 2026",
    "System design\nArchitectural design\nDatabase design\nWireframes\nInitial functional prototype"],
   ["5", "Basic Prototype and Project Progress Report", "10 June 2026 (submission by 13 June 2026)",
    "Basic system prototype\nProject Progress Report\nPreliminary technical documents\nPreliminary user manual\nPeer assessment form"],
   ["6", "End of Term 1 Review", "20 June 2026",
    "Prototype demonstration of basic functionalities\nTerm 2 development direction"],
   ["7", "Functional Modules and Module Testing", "11 July 2026",
    "Individual functional modules\nCentralised database prepared\nModule test plan completed\nModule-level testing carried out"],
   ["8", "Integrated Module Functionalities and Integration Testing", "1 August 2026",
    "Integrated module functionalities\nIntegration testing\nTechnical documentation updated\nDraft user manual\nIntegration test summary"],
   ["9", "Final Product Demonstration to Supervisor", "13 August 2026 (submission by 15 August 2026)",
    "Final product demonstrated\nFinal technical documentation\nFinal user manual\nProject video\nPresentation slides"],
   ["10", "Final Project Presentation and Demonstration", "22 August 2026",
    "Final product demonstrated to supervisor and assessor\nFinal documentation submitted\nUser manual\nProject video\nPeer assessment form\nSource code"],
 ]),
])

# =====================================================================
# 5.4 Project Charter
# =====================================================================
fill_after("5.4 Project Charter", [
 ("tbl", [
   ["Field", "Detail"],
   ["Project name", "Wise Workout - A Mobile Application for Wise Workout"],
   ["Project code", "CSIT-26-S2-05 - Group FYP-26-S2-37"],
   ["Module", "CSIT321 Final Year Project (UOW / SIM)"],
   ["Supervisor", "Mr Premrajan"],
   ["Duration", "4 April 2026 - 22 August 2026 (two terms)"],
   ["Project coordinator", "Chia Yuan Jun"],
   ["Purpose", "Deliver a cross-platform mobile fitness application that integrates workout "
       "tracking, AI-assisted progress summaries and plan suggestions, a verified-expert services "
       "marketplace, and a social/challenge layer, supported by a marketing website and an admin "
       "portal."],
   ["Objectives", "(1) Build the core capture - analyse - AI-summary - share loop. "
       "(2) Implement all five user roles. (3) Deliver Free/Premium/Expert-services monetisation "
       "(simulated payment). (4) Apply a maintainable BCE architecture with role-based plus "
       "row-level security. (5) Produce the required FYP deliverables."],
   ["In scope", "Mobile app (Android + iOS via Flutter); marketing website; admin portal; "
       "phone-sensor and manual workout capture; AI summaries/suggestions via a secure backend "
       "function; expert listings, requests, and deliverables; social feed, challenges, friends; "
       "subscriptions; admin moderation."],
   ["Out of scope (this phase)", "Real payment-gateway settlement (simulated only); live "
       "wearable/HealthKit/BLE sync (provisioned, additive later); push/FCM notifications (local "
       "only initially); nutrition tracking; non-English localisation."],
   ["Key deliverables", "PRD, SRS, TDM, PTD + PUM (approx. 13 June), End-of-Term-1 review "
       "(20 June), module and integration testing, final working system and demonstration "
       "(13-22 August)."],
   ["Stakeholders", "Project team (4), supervisor/assessors (UOW/SIM), prospective end users "
       "(free/premium/expert), evaluators."],
   ["Team & roles", "Chia Yuan Jun - coordination & documentation; Devanandi Praveen - mobile / "
       "UI; Foong Jun Yan - backend / database / API; Jedidiah Goh - website / expert & admin "
       "features."],
   ["Success criteria", "Core vertical slice demonstrable end-to-end; all five roles functional; "
       "deliverables submitted on schedule and internally consistent; architecture and security "
       "requirements met; positive supervisor/assessor evaluation."],
   ["Top constraints", "Fixed FYP timeline and team size; reliance on third-party services "
       "(Supabase, OpenAI/Gemini); Android/iOS build/test requires configured SDKs and "
       "emulator/simulator devices."],
   ["Top assumptions", "Users have compatible smartphones and connectivity; third-party services "
       "remain available within budget; wearables (if used later) support standard data-sharing."],
 ]),
])

# =====================================================================
# 5.5 Communication Management Plan
# =====================================================================
fill_after("5.5 Communication", [
 ("p", "Objective: keep the team, supervisor, and documents synchronised, and define how "
       "decisions and changes are recorded."),
 ("pb", "Stakeholders and channels"),
 ("tbl", [
   ["Stakeholder", "Primary channel", "Cadence"],
   ["Project team (internal)", "Team chat (WhatsApp/Discord)", "Daily / as needed"],
   ["Team working sessions", "Video call + screen share", "1-2x per week"],
   ["Supervisor (Mr Premrajan)", "Scheduled meetings + email", "Weekly / per milestone"],
   ["Code collaboration", "GitHub (repo, issues, pull requests)", "Continuous"],
   ["Documents & assets", "Shared drive (Word deliverables, diagrams)", "Continuous"],
   ["Assessors / evaluators", "Formal submissions + presentations", "At each milestone"],
 ]),
 ("pb", "Meeting types"),
 ("bul", "Weekly team sync - progress, blockers, and next-sprint tasks (Agile)."),
 ("bul", "Supervisor meeting - milestone review, feedback, and sign-off before each submission."),
 ("bul", "Ad-hoc design huddles - for architecture or scope decisions."),
 ("pb", "Escalation path"),
 ("p", "Team member - project coordinator (Yuan Jun) - supervisor. Technical blockers older than "
       "about two working days are escalated at the weekly sync."),
 ("pb", "Document and change control"),
 ("bul", "Every deliverable carries a version-control table (version, date, author, description)."),
 ("bul", "Engineering decisions that diverge from a submitted document are recorded in the "
       "document reconciliation log and folded into the next revision of the affected document."),
 ("bul", "Major scope or architecture changes require team agreement at a sync and supervisor "
       "awareness at the next meeting."),
])

# =====================================================================
# 6.1 Stakeholder Identification
# =====================================================================
fill_after("6.1 Stakeholder", [
 ("p", "Requirements were gathered with the following stakeholders in mind, each contributing a "
       "different set of needs:"),
 ("bul", "End users (Free and Premium) - the primary actors whose tracking, analytics, AI, and "
       "social needs drive most functional requirements."),
 ("bul", "Verified experts - whose profile, service-listing, and request-handling needs define "
       "the expert-services layer."),
 ("bul", "System administrators - whose verification, moderation, and content-management needs "
       "define the admin functions."),
 ("bul", "The project team - balancing scope against the FYP timeline and technical feasibility."),
 ("bul", "The supervisor and assessors - whose rubric and milestone expectations shape the "
       "deliverable and quality requirements."),
])

# =====================================================================
# 6.3 Requirement Analysis Approach
# =====================================================================
fill_after("6.3 Requirement Analysis", [
 ("p", "Gathered requirements were analysed and refined into the prioritised set implemented in "
       "the prototype, using the following approach:"),
 ("bul", "Core-first prioritisation - the capture - analyse - AI-summary - share loop and the "
       "five user roles were treated as must-have; expert-content depth and admin-monitoring depth "
       "yield first if time runs short."),
 ("bul", "Role-based decomposition - requirements were grouped by actor (unregistered, free, "
       "premium, expert, admin) to keep access levels and use cases consistent."),
 ("bul", "Traceability - each requirement maps to a user story and a use case, and is reflected "
       "in the BCE design (one control per use case)."),
 ("bul", "Reconciliation - where engineering decisions diverged from earlier documents (for "
       "example the backend stack and AI scope), changes were recorded in a reconciliation log so "
       "the documents stay consistent."),
 ("bul", "Feasibility review - requirements were checked against the chosen stack (Flutter, "
       "Supabase, AI services) and the prototype timeline before being committed."),
])

# =====================================================================
# 7.1 Functional Hierarchy
# =====================================================================
fill_after("7.1 Functional", [
 ("p", "The system's functionality is organised into twelve functional requirement groups "
       "(FR1-FR12). Each group decomposes into the use cases and screens described in the SRS and "
       "Section 13-14."),
 ("rbul", [("FR1 User Account and Authentication - ", True), ("register, log in, and access the "
       "platform based on user category and subscription tier.", False)]),
 ("rbul", [("FR2 Fitness Profile Management - ", True), ("create and manage a fitness profile "
       "holding goals, activity preferences, and personal fitness needs.", False)]),
 ("rbul", [("FR3 Workout Activity Recording - ", True), ("record workout activities such as "
       "running, cycling, gym training, walking, strength, stretching, and recovery.", False)]),
 ("rbul", [("FR4 Data Acquisition and Wearable Integration - ", True), ("acquire data from phone "
       "sensors, wearables, and health platforms (simulated wearable HR in the prototype).", False)]),
 ("rbul", [("FR5 Progress Dashboard and Analytics - ", True), ("present workout history, activity "
       "trends, and performance summaries (advanced analytics for Premium).", False)]),
 ("rbul", [("FR6 AI-Assisted Progress Summaries and Fitness Plan Suggestions - ", True),
       ("generate progress summaries and plan suggestions from profile, history, goals, and "
       "preferences (basic for Free, personalised for Premium).", False)]),
 ("rbul", [("FR7 Fitness Plan, Reminder, and Alert Management - ", True), ("manage fitness plans, "
       "workout reminders, rest alerts, and progress notifications (rule-based).", False)]),
 ("rbul", [("FR8 Expert Profile and Service Management - ", True), ("verified experts create and "
       "manage professional profiles and service listings.", False)]),
 ("rbul", [("FR9 Expert Discovery and Service Requests - ", True), ("browse, search, and filter "
       "experts and request services as a paid add-on layer.", False)]),
 ("rbul", [("FR10 Community Feed, Social Sharing, Competitions, and Gamification - ", True),
       ("post to a community feed, join challenges, earn achievements, and share results to named "
       "platforms.", False)]),
 ("rbul", [("FR11 Subscription and Tiered Access Control - ", True), ("enforce access levels for "
       "free users, premium users, and expert services (simulated payment).", False)]),
 ("rbul", [("FR12 Administrative Management - ", True), ("manage users, approve expert "
       "applications, manage categories, and monitor expert content and listings.", False)]),
])

# =====================================================================
# 7.2 Basic Feature Access Levels
# =====================================================================
fill_after("7.2 Basic Feature", [
 ("p", "Access to functionality is governed by the user's tier. The high-level access levels are:"),
 ("tbl", [
   ["User Tier", "Access Level"],
   ["Unregistered User", "View the marketing website, read general platform information, view "
       "subscription highlights, and create an account."],
   ["Registered Free User", "Basic fitness tracking, basic progress summaries, basic AI progress "
       "summaries and basic AI-assisted plan suggestions, social features, and expert browsing."],
   ["Registered Premium User", "Full platform tools - advanced analytics, personalised AI "
       "summaries, personalised AI-assisted plan suggestions, personalised reports, and "
       "personalised reminders and alerts."],
   ["Expert User", "Offer paid professional services through verified profiles, content, service "
       "listings, and user service requests."],
   ["System Admin", "Manage platform operations - users, expert verification, categories, "
       "content, service listings, and quality control."],
 ]),
 ("p", "Expert services are a separate paid layer that both Free and Premium users can purchase; "
       "they are not bundled into the Premium subscription."),
])

# =====================================================================
# 7.3 Dependencies
# =====================================================================
fill_after("7.3 Dependencies", [
 ("p", "The functional requirements depend on the following internal and external prerequisites:"),
 ("bul", "Authentication first - a user must register and log in (FR1) before any tracking, "
       "analytics, AI, social, or expert feature is available."),
 ("bul", "Profile and goal data - AI summaries and plan suggestions (FR6) depend on the fitness "
       "profile and an active goal (FR2)."),
 ("bul", "Workout history - analytics (FR5) and summaries (FR6) depend on recorded sessions (FR3/"
       "FR4)."),
 ("bul", "Expert verification - service listings and requests (FR8/FR9) depend on an admin "
       "verifying the expert (FR12)."),
 ("bul", "Subscription state - advanced analytics and personalised AI (FR5/FR6) depend on the "
       "user's tier (FR11)."),
 ("bul", "External services - the backend depends on Supabase (database, auth, storage, edge "
       "functions); AI features depend on OpenAI/Gemini with a rule-based fallback; sensor capture "
       "depends on device location/motion permissions."),
])

# =====================================================================
# 7.4 Inputs and Outputs
# =====================================================================
fill_after("7.4 Inputs", [
 ("p", "The principal inputs and outputs for the core functions are summarised below."),
 ("tbl", [
   ["Function", "Inputs", "Outputs"],
   ["Authentication (FR1)", "Email, password", "Authenticated session, profile record"],
   ["Fitness profile & goals (FR2)", "Body metrics, activity level, experience, preferences, goal",
    "Stored profile and active goal"],
   ["Workout capture (FR3/FR4)", "Workout type, phone-sensor stream (GPS/steps), simulated HR",
    "Workout session (distance, duration, pace, calories, HR), XP/streak update"],
   ["Analytics (FR5)", "Workout history, profile", "Dashboards, trends, weekly/monthly summaries"],
   ["AI summary / plan (FR6)", "Profile, goal, workout history", "AI-assisted summary; suggested "
       "fitness plan (basic or personalised)"],
   ["Expert services (FR8/FR9)", "Service listing, service request", "Service status, expert "
       "deliverable, review"],
   ["Subscription (FR11)", "Tier change, simulated payment", "Updated subscription status and "
       "access level"],
 ]),
])

# =====================================================================
# 8.1 Performance Requirements
# =====================================================================
fill_after("8.1 Performance", [
 ("p", "As a prototype, performance is targeted at smooth demonstration on the Android emulator "
       "and iOS simulator rather than production load. The key expectations are:"),
 ("bul", "Common screens (login, home, history, profile) should load and respond within a "
       "couple of seconds on the test devices."),
 ("bul", "Workout capture should update live metrics smoothly without blocking the UI; sensor "
       "teardown is non-blocking so ending a session stays responsive."),
 ("bul", "AI summary and plan generation should return within a reasonable time and degrade "
       "gracefully to a rule-based fallback if the provider is slow or unavailable."),
 ("bul", "History queries are bounded (the Free tier is capped to the current calendar month at "
       "the query level) to keep reads fast."),
 ("bul", "The hosted Supabase backend should handle the prototype's demonstration workload "
       "reliably; cloud scaling is a future-development concern."),
])

# =====================================================================
# 10. Risk Management
# =====================================================================
fill_after("10. Risk", [
 ("p", "Risk analysis is important because the system spans several connected components - the "
       "mobile app, marketing website, backend, database, AI features, sensor/wearable data "
       "acquisition, expert workflows, subscriptions, social features, and admin management. "
       "Identifying risks early lets the team plan mitigation and reduce the chance of delays or "
       "incomplete features. The main risks relate to scope, integration, data privacy, AI output "
       "quality, and wearable data acquisition; they are managed through Agile iterative "
       "development, core-first prioritisation, regular module testing, and scope adjustment based "
       "on time and feasibility."),
 ("tbl", [
   ["Risk Category", "Identified Risk", "Possible Impact", "Mitigation Strategy"],
   ["Communication", "Miscommunication between team members during development",
    "Tasks may be duplicated, delayed, or implemented inconsistently",
    "Hold regular discussions, maintain clear task assignments, and update progress against the schedule."],
   ["Schedule", "Project scope may be too large for the FYP timeline",
    "Some features may be incomplete or rushed",
    "Prioritise core features first - accounts, fitness profile, workout recording, dashboard, expert flow, admin."],
   ["Technical", "Wearable/sensor integration may be hard to implement fully",
    "Automatic data collection may be limited in the prototype",
    "Support manual workout input and selected prototype-level integration where possible."],
   ["Technical", "App, website, backend, and database integration may cause issues",
    "The system may not work smoothly during testing or demonstration",
    "Carry out module testing and integration testing before the final demonstration."],
   ["AI-related", "AI summaries and plan suggestions may be less accurate with limited data",
    "New users may receive less accurate or less personalised output",
    "Use rule-based logic first and improve output as more workout data becomes available."],
   ["Data quality", "Users may enter incomplete or inaccurate fitness information",
    "Recommendations, analytics, and summaries may be less useful",
    "Use validation checks and clear input fields to encourage accurate data entry."],
   ["Security and privacy", "Fitness and health data are sensitive",
    "User trust may be affected if data is mishandled",
    "Collect only necessary data, restrict access by role, and limit what is shared with experts."],
   ["Usability", "The app may become hard to use with many features",
    "Users may feel confused or avoid certain functions",
    "Design simple flows, organise features clearly, and conduct usability testing."],
   ["Expert service", "Expert verification and request workflows may be complex",
    "Expert features may take longer to develop",
    "Prioritise expert profiles, listings, and request handling before advanced functions."],
   ["Payment", "Full payment-gateway integration may be hard within the timeline",
    "Subscription and expert-payment features may not be fully functional",
    "Use simulated payment status or manually assigned access levels to demonstrate access control."],
   ["Social features", "Social/external-platform integration depends on third-party restrictions",
    "Direct sharing to some platforms may be limited",
    "Provide basic shareable summaries or simulated sharing where full API integration is not possible."],
   ["Testing", "Cross-platform testing may be limited by device availability",
    "UI or performance issues may appear on some devices",
    "Test on Android emulators, iOS simulators, and available physical devices."],
   ["Maintenance", "Changes in external APIs, AI services, or wearable platforms",
    "Future versions may require updates",
    "Design with modular components so integrations can be updated more easily."],
   ["Reliability", "Notifications and reminders may not always be delivered",
    "Users may miss workout reminders or rest alerts",
    "Test reminder logic and provide in-app notification history where possible."],
   ["Scalability", "Backend performance under many users in future",
    "The system may slow down under high usage",
    "Focus the prototype on functional demonstration; future work includes cloud scaling."],
 ]),
])

# =====================================================================
# 18. Glossary
# =====================================================================
fill_after("18. Glossary", [
 ("tbl", [
   ["Term", "Definition"],
   ["BCE (Boundary-Control-Entity)", "An architecture pattern (Jacobson) separating actor-facing "
       "Boundaries, use-case Controls, and data Entities; the rule is Actor - Boundary - Control - "
       "Entity."],
   ["Boundary", "A component at the system edge - a UI screen/widget or a system-facing "
       "gateway/adapter."],
   ["Control", "A class implementing one use case; mediates between Boundaries and Entities."],
   ["Entity", "A domain object holding data and data-owned rules (e.g. XP, level, streak)."],
   ["Gateway", "A system-facing boundary that talks to an external system (database, AI, sensors, "
       "social, notifications, storage)."],
   ["Supabase", "The managed backend: PostgreSQL database + Auth + Storage + Realtime + Edge "
       "Functions."],
   ["Edge Function", "A server-side function (on Supabase) used to proxy the AI provider so the "
       "API key never ships in the app."],
   ["RLS (Row-Level Security)", "Database rules that restrict which rows a user can read/write, "
       "enforcing privacy invariants (e.g. private workout notes)."],
   ["Flutter / Dart", "The cross-platform UI framework / language used to build the Android + iOS "
       "app from one codebase."],
   ["Riverpod", "The app's state-management library; a Control is implemented as a Riverpod "
       "notifier the UI watches."],
   ["go_router", "The routing library; handles role-based navigation/redirects."],
   ["ERD (Entity-Relationship Diagram)", "The database design showing entities and their "
       "relationships."],
   ["DFD (Data Flow Diagram)", "A model of how data moves between external entities, processes, "
       "and data stores."],
   ["FR / NFR", "Functional Requirement (what the system does) / Non-Functional Requirement "
       "(quality attributes - security, performance, etc.)."],
   ["Use case", "A described interaction between an actor and the system to achieve a goal (the "
       "SRS defines 64)."],
   ["Three-layer model", "The business model: Free, Premium, and a separate a-la-carte "
       "Expert-services layer that both Free and Premium users can purchase."],
   ["AI-assisted summary", "A machine-generated recap of a user's progress - informational, not "
       "medical advice."],
   ["AI plan suggestion", "A machine-suggested training plan (Premium = personalised); distinct "
       "from human-expert custom plans."],
   ["Suggested vs Freeform workout", "A workout started from a plan's prescribed session vs an "
       "unstructured one the user starts on the spot."],
   ["Deliverable", "Content an expert produces for a client within a paid engagement (e.g. a form "
       "review or custom block)."],
   ["Service request", "A user's paid request against an expert's service listing."],
   ["PDPA", "Singapore's Personal Data Protection Act, governing personal-data handling."],
   ["Simulated payment", "Subscription/expert-service purchase flows modelled with price fields "
       "and status only - no real gateway or card data."],
 ]),
])

doc.save(OUT)
print("Saved:", OUT)
# verify no placeholders & count remaining empty sections
chk = docx.Document(OUT)
ph = sum(1 for p in chk.paragraphs if "Subsection" in p.text and "content" in p.text)
print("Remaining 'Subsection content' placeholders:", ph)
print("Total tables now:", len(chk.tables))
