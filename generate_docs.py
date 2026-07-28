"""
Generates professional colored diagrams (Graphviz SVG) and builds a clean
PDF via Chrome headless.

Color used only in:  diagrams · table headers · callout boxes
Body text:           plain black on white — professional document style
"""

import os, subprocess, pathlib, base64, textwrap

GRAPHVIZ_DOT = "/opt/homebrew/bin/dot"
OUT_DIR = pathlib.Path("/Users/enajafi/Flutter_Projects/food_app")
SVG_DIR = OUT_DIR / "_doc_svgs"
SVG_DIR.mkdir(exist_ok=True)


def render_dot(name: str, dot_src: str) -> pathlib.Path:
    """Write DOT source, render to SVG, return the SVG file path."""
    dot_file = SVG_DIR / f"{name}.dot"
    svg_file  = SVG_DIR / f"{name}.svg"
    dot_file.write_text(dot_src)
    subprocess.run(
        [GRAPHVIZ_DOT, "-Tsvg", str(dot_file), "-o", str(svg_file)],
        check=True, capture_output=True
    )
    return svg_file


# ─────────────────────────────────────────────────────────────────────────────
# DIAGRAM DEFINITIONS
# ─────────────────────────────────────────────────────────────────────────────

def diag_architecture():
    return render_dot("architecture", """
digraph Architecture {
    graph [rankdir=TB fontname="Helvetica" bgcolor="#FAFAFA"
           pad=0.8 nodesep=0.8 ranksep=1.1 splines=curved]
    node  [fontname="Helvetica" fontsize=12 style="filled,rounded" penwidth=2]
    edge  [fontname="Helvetica" fontsize=10 penwidth=2]

    /* ── PHONE (top) ─────────────────────────────── */
    subgraph cluster_phone {
        label="Your Phone  (Flutter App)"
        style=filled fillcolor="#E3F2FD" color="#1565C0"
        fontname="Helvetica Bold" fontsize=13 fontcolor="#0D47A1" penwidth=2.5

        Customer [label="Customer\nDashboard" fillcolor="#BBDEFB" color="#1565C0" fontcolor="#0D47A1"]
        Business [label="Business\nDashboard" fillcolor="#BBDEFB" color="#1565C0" fontcolor="#0D47A1"]
        Admin    [label="Admin\nDashboard"    fillcolor="#BBDEFB" color="#1565C0" fontcolor="#0D47A1"]
    }

    /* ── MIDDLE ROW ──────────────────────────────── */
    Keycloak [label="KEYCLOAK\nSecurity Guard\n─────────────\nChecks passwords\nIssues digital keys"
              shape=box fillcolor="#EDE7F6" color="#4527A0" fontcolor="#311B92"
              fontname="Helvetica Bold" fontsize=12]

    JWTStore [label="Digital Key (JWT Token)\nstored securely inside the phone\n─────────────────────────────\nContains: who you are + your role\nExpires in 5 minutes"
              shape=note fillcolor="#FFF9C4" color="#F57F17" fontcolor="#E65100"
              fontname="Helvetica" fontsize=11]

    Symfony  [label="SYMFONY API\nBrain of the System\n─────────────────\nAll business logic:\norders, offers, users"
              shape=box fillcolor="#E8F5E9" color="#1B5E20" fontcolor="#1B5E20"
              fontname="Helvetica Bold" fontsize=12]

    /* ── BOTTOM ROW ──────────────────────────────── */
    MySQL    [label="MySQL Database\n─────────────────\nAll data lives here:\nusers, orders, offers\naddresses, reviews"
              shape=cylinder fillcolor="#FFE0B2" color="#E65100" fontcolor="#BF360C"
              fontname="Helvetica" fontsize=11]

    FCM      [label="Firebase FCM\n─────────────────\nPush Notifications\nto business staff"
              shape=box fillcolor="#E1F5FE" color="#0288D1" fontcolor="#01579B"
              fontname="Helvetica" fontsize=11]

    /* ── ARROWS WITH NUMBERED STEPS ─────────────── */

    /* Purple = Login flow (happens once when you open the app) */
    Customer -> Keycloak [
        label="  STEP 1\n  You log in with\n  email + password"
        color="#6A1B9A" fontcolor="#4A148C" penwidth=2.5
    ]
    Business -> Keycloak [color="#6A1B9A" penwidth=2]
    Admin    -> Keycloak [color="#6A1B9A" penwidth=2]

    Keycloak -> JWTStore [
        label="  STEP 2\n  Guard gives you\n  a digital key"
        color="#6A1B9A" fontcolor="#4A148C" penwidth=2.5
    ]

    /* Green = Data flow (happens on every screen / button tap) */
    JWTStore -> Symfony [
        label="  STEP 3\n  Every request shows\n  the digital key"
        color="#2E7D32" fontcolor="#1B5E20" penwidth=2.5
    ]

    /* Dashed purple = Background security check (invisible to user) */
    Symfony -> Keycloak [
        label="STEP 4  \nBackground check:  \n'Is this key genuine?'  "
        style=dashed color="#6A1B9A" fontcolor="#4A148C" penwidth=1.8
        dir=both arrowhead=none arrowtail=normal
    ]

    /* Orange = Database read/write */
    Symfony -> MySQL [
        label="  STEP 5\n  Read or save data\n  (orders, offers...)"
        color="#E65100" fontcolor="#BF360C" penwidth=2.5
    ]

    /* Blue = Push notification */
    Symfony -> FCM [
        label="  STEP 6\n  New order arrived!\n  Notify staff phone"
        color="#0288D1" fontcolor="#01579B" penwidth=2
    ]

    /* Force layout order */
    {rank=same Keycloak JWTStore Symfony}
    {rank=same MySQL FCM}
}
""")


def diag_auth_flow():
    return render_dot("auth_flow", """
digraph AuthFlow {
    graph [rankdir=TB fontname="Helvetica" splines=ortho bgcolor="#FAFAFA" pad=0.5 nodesep=0.55 ranksep=0.85]
    node  [fontname="Helvetica" fontsize=12 style="filled,rounded" penwidth=2]
    edge  [fontname="Helvetica" fontsize=10 penwidth=1.6]

    S1 [label="User enters email + password" shape=box fillcolor="#ECEFF1" color="#455A64"]
    S2 [label="POST /token  (grant_type=password)" shape=box fillcolor="#BBDEFB" color="#1565C0" fontcolor="#0D47A1"]
    S3 [label="Keycloak verifies credentials" shape=box fillcolor="#E1BEE7" color="#6A1B9A" fontcolor="#4A148C"]
    S4 [label="Returns JWT\naccess_token (5 min)\nrefresh_token (hours)" shape=box fillcolor="#DCEDC8" color="#2E7D32" fontcolor="#1B5E20"]
    S5 [label="App saves tokens\nin encrypted Keychain" shape=box fillcolor="#ECEFF1" color="#455A64"]
    S6 [label="API Request  —  Authorization: Bearer token" shape=box fillcolor="#BBDEFB" color="#1565C0" fontcolor="#0D47A1"]
    S7 [label="Symfony validates JWT\nsignature + expiry" shape=box fillcolor="#E1BEE7" color="#6A1B9A" fontcolor="#4A148C"]
    S8 [label="Load User from MySQL by email" shape=box fillcolor="#C8E6C9" color="#2E7D32" fontcolor="#1B5E20"]
    S9 [label="Return API Response" shape=box fillcolor="#DCEDC8" color="#2E7D32" fontcolor="#1B5E20"]

    Expired [label="Token expired?" shape=diamond fillcolor="#FFF9C4" color="#F57F17" fontcolor="#E65100"]
    Refresh [label="Use refresh_token\nfor new access_token" shape=box fillcolor="#FFF9C4" color="#F57F17" fontcolor="#E65100"]
    Fail    [label="Refresh failed\nForce logout to Login" shape=box fillcolor="#FFCDD2" color="#C62828" fontcolor="#B71C1C"]

    S1 -> S2 -> S3 -> S4 -> S5 -> S6 -> Expired
    Expired -> S7   [label="No, still valid" color="#2E7D32" fontcolor="#2E7D32"]
    Expired -> Refresh [label="Yes" color="#F57F17" fontcolor="#F57F17"]
    Refresh -> S7   [label="New token OK" color="#2E7D32" fontcolor="#2E7D32"]
    Refresh -> Fail [label="Also failed" color="#C62828" fontcolor="#C62828"]
    S7 -> S8 -> S9
}
""")


def diag_jwt_structure():
    return render_dot("jwt_structure", """
digraph JWT {
    graph [rankdir=LR fontname="Helvetica" bgcolor="#FAFAFA" pad=0.5 nodesep=0.5 ranksep=1.0]
    node  [fontname="Helvetica" fontsize=12 style="filled,rounded" penwidth=2]
    edge  [fontname="Helvetica" fontsize=11 penwidth=1.5]

    JWT [label="JWT Token\n(3 dot-separated parts)" shape=box fillcolor="#E1BEE7" color="#6A1B9A" fontcolor="#4A148C" fontname="Helvetica Bold" fontsize=14]

    H [label="Header\n──────────\nalgorithm: RS256\ntype: JWT" shape=box fillcolor="#BBDEFB" color="#1565C0" fontcolor="#0D47A1"]
    P [label="Payload\n──────────────\nsub: user-uuid\nemail: user@mail.com\nrealm_access.roles: [ROLE_USER]\nexp: unix-timestamp" shape=box fillcolor="#C8E6C9" color="#2E7D32" fontcolor="#1B5E20"]
    S [label="Signature\n──────────\nRSA-signed by Keycloak\nprivate key (tamper-proof)" shape=box fillcolor="#FFE0B2" color="#E65100" fontcolor="#BF360C"]

    Roles  [label="ROLE_USER → Customer app"          shape=box fillcolor="#ECEFF1" color="#455A64" fontsize=11]
    RolesB [label="ROLE_BUSINESS_PARTNER → Business"  shape=box fillcolor="#ECEFF1" color="#455A64" fontsize=11]
    RolesA [label="ROLE_ADMIN → Admin dashboard"      shape=box fillcolor="#ECEFF1" color="#455A64" fontsize=11]

    JWT -> H
    JWT -> P
    JWT -> S
    P -> Roles  [style=dashed color="#455A64"]
    P -> RolesB [style=dashed color="#455A64"]
    P -> RolesA [style=dashed color="#455A64"]
}
""")


def diag_registration():
    return render_dot("registration", """
digraph Registration {
    graph [rankdir=TB fontname="Helvetica" splines=ortho bgcolor="#FAFAFA" pad=0.6 nodesep=0.5 ranksep=0.7]
    node  [fontname="Helvetica" fontsize=12 style="filled,rounded" penwidth=2]
    edge  [fontname="Helvetica" fontsize=10 penwidth=1.8]

    Start  [label="User fills Registration Form\nemail, password, name, account type" shape=box fillcolor="#ECEFF1" color="#455A64" fontname="Helvetica Bold"]
    Post   [label="POST /api/register" shape=box fillcolor="#BBDEFB" color="#1565C0" fontcolor="#0D47A1"]

    Step1  [label="Step 1: Get Admin Token\nKeycloak client_credentials flow" shape=box fillcolor="#E1BEE7" color="#6A1B9A" fontcolor="#4A148C"]
    Step2  [label="Step 2: Create User in Keycloak\nPOST /admin/realms/realm/users" shape=box fillcolor="#E1BEE7" color="#6A1B9A" fontcolor="#4A148C"]
    Conflict [label="409 — Email already taken" shape=box fillcolor="#FFCDD2" color="#C62828" fontcolor="#B71C1C"]
    Step3  [label="Step 3: Assign Role in Keycloak\nROLE_USER or ROLE_BUSINESS_PARTNER" shape=box fillcolor="#E1BEE7" color="#6A1B9A" fontcolor="#4A148C"]
    Step4a [label="Step 4a: Save User row in MySQL" shape=box fillcolor="#FFE0B2" color="#E65100" fontcolor="#BF360C"]
    IsBiz  [label="Account type\n= business?" shape=diamond fillcolor="#FFF9C4" color="#F57F17" fontcolor="#E65100"]
    Step4b [label="Step 4b: Create BusinessPartner row\nkycStatus=pending, isActive=true" shape=box fillcolor="#FFE0B2" color="#E65100" fontcolor="#BF360C"]
    Done   [label="201 Created — User can now log in" shape=box fillcolor="#DCEDC8" color="#2E7D32" fontcolor="#1B5E20" fontname="Helvetica Bold"]

    Start -> Post -> Step1 -> Step2
    Step2 -> Conflict [label="Email exists" color="#C62828" fontcolor="#C62828"]
    Step2 -> Step3    [label="201 OK" color="#2E7D32" fontcolor="#2E7D32"]
    Step3 -> Step4a -> IsBiz
    IsBiz -> Step4b [label="Yes" color="#6A1B9A" fontcolor="#6A1B9A"]
    IsBiz -> Done   [label="No (customer)" color="#2E7D32" fontcolor="#2E7D32"]
    Step4b -> Done
}
""")


def diag_role_routing():
    return render_dot("role_routing", """
digraph RoleRouting {
    graph [rankdir=LR fontname="Helvetica" bgcolor="#FAFAFA" pad=0.6 nodesep=0.6 ranksep=1.1]
    node  [fontname="Helvetica" fontsize=12 style="filled,rounded" penwidth=2]
    edge  [fontname="Helvetica" fontsize=11 penwidth=1.8]

    AppLaunch  [label="App Launch\nAuth Gate" shape=box fillcolor="#ECEFF1" color="#455A64" fontname="Helvetica Bold"]
    TokenCheck [label="Valid token in Keychain?" shape=diamond fillcolor="#FFF9C4" color="#F57F17" fontcolor="#E65100"]
    Login      [label="Login Screen" shape=box fillcolor="#FFCDD2" color="#C62828" fontcolor="#B71C1C"]
    ReadRoles  [label="Read roles from JWT" shape=box fillcolor="#E1BEE7" color="#6A1B9A" fontcolor="#4A148C"]

    AdminDash    [label="Admin Dashboard\nAll data visible" shape=box fillcolor="#D1C4E9" color="#4527A0" fontcolor="#311B92"]
    BizDash      [label="Business Dashboard\nOrders, Menu, Earnings" shape=box fillcolor="#C8E6C9" color="#2E7D32" fontcolor="#1B5E20"]
    CustomerDash [label="Customer App\nBrowse and order" shape=box fillcolor="#BBDEFB" color="#1565C0" fontcolor="#0D47A1"]

    R_Admin [label="ROLE_ADMIN"            shape=box fillcolor="#ECEFF1" color="#4527A0" fontsize=11]
    R_Biz   [label="ROLE_BUSINESS_PARTNER" shape=box fillcolor="#ECEFF1" color="#2E7D32" fontsize=11]
    R_Mem   [label="ROLE_MEMBER"           shape=box fillcolor="#ECEFF1" color="#2E7D32" fontsize=11]
    R_User  [label="ROLE_USER"             shape=box fillcolor="#ECEFF1" color="#1565C0" fontsize=11]

    AppLaunch -> TokenCheck
    TokenCheck -> Login      [label="No" color="#C62828" fontcolor="#C62828"]
    TokenCheck -> ReadRoles  [label="Yes" color="#2E7D32" fontcolor="#2E7D32"]
    ReadRoles -> R_Admin -> AdminDash     [color="#4527A0"]
    ReadRoles -> R_Biz   -> BizDash      [color="#2E7D32"]
    ReadRoles -> R_Mem   -> BizDash      [color="#2E7D32"]
    ReadRoles -> R_User  -> CustomerDash [color="#1565C0"]
}
""")


def diag_database():
    return render_dot("database", """
digraph Database {
    graph [fontname="Helvetica" bgcolor="#FAFAFA" pad=0.7 nodesep=0.6 ranksep=1.1 splines=ortho]
    node  [fontname="Helvetica" fontsize=11 style="filled" shape=none penwidth=0]
    edge  [fontname="Helvetica" fontsize=10 penwidth=1.6 arrowsize=0.9]

    User [label=<
        <TABLE BORDER="0" CELLBORDER="1" CELLSPACING="0" CELLPADDING="5" BGCOLOR="#BBDEFB">
        <TR><TD COLSPAN="2" BGCOLOR="#1565C0"><FONT COLOR="white"><B>user</B></FONT></TD></TR>
        <TR><TD ALIGN="LEFT"><B>id</B> (INT, PK)</TD><TD ALIGN="LEFT">auto-increment</TD></TR>
        <TR><TD ALIGN="LEFT"><B>uuid</B></TD><TD ALIGN="LEFT">public API identifier</TD></TR>
        <TR><TD ALIGN="LEFT">firstName, lastName</TD><TD ALIGN="LEFT">string</TD></TR>
        <TR><TD ALIGN="LEFT">email</TD><TD ALIGN="LEFT">unique</TD></TR>
        <TR><TD ALIGN="LEFT">roles</TD><TD ALIGN="LEFT">JSON array</TD></TR>
        <TR><TD ALIGN="LEFT">businessPartner_id</TD><TD ALIGN="LEFT">FK (null = customer)</TD></TR>
        </TABLE>>]

    BusinessPartner [label=<
        <TABLE BORDER="0" CELLBORDER="1" CELLSPACING="0" CELLPADDING="5" BGCOLOR="#C8E6C9">
        <TR><TD COLSPAN="2" BGCOLOR="#2E7D32"><FONT COLOR="white"><B>business_partner</B></FONT></TD></TR>
        <TR><TD ALIGN="LEFT"><B>id</B> (INT, PK)</TD><TD ALIGN="LEFT">auto-increment</TD></TR>
        <TR><TD ALIGN="LEFT">businessName</TD><TD ALIGN="LEFT">string</TD></TR>
        <TR><TD ALIGN="LEFT">kycStatus</TD><TD ALIGN="LEFT">pending/approved/rejected</TD></TR>
        <TR><TD ALIGN="LEFT">isActive</TD><TD ALIGN="LEFT">boolean (open/closed)</TD></TR>
        <TR><TD ALIGN="LEFT">deliveryFee</TD><TD ALIGN="LEFT">decimal</TD></TR>
        <TR><TD ALIGN="LEFT">bankAccountNr, iban</TD><TD ALIGN="LEFT">banking info</TD></TR>
        </TABLE>>]

    FoodOffer [label=<
        <TABLE BORDER="0" CELLBORDER="1" CELLSPACING="0" CELLPADDING="5" BGCOLOR="#FFE0B2">
        <TR><TD COLSPAN="2" BGCOLOR="#E65100"><FONT COLOR="white"><B>food_offer</B></FONT></TD></TR>
        <TR><TD ALIGN="LEFT"><B>id</B> (INT, PK)</TD><TD ALIGN="LEFT">auto-increment</TD></TR>
        <TR><TD ALIGN="LEFT">title, category</TD><TD ALIGN="LEFT">string</TD></TR>
        <TR><TD ALIGN="LEFT">originPrice, price</TD><TD ALIGN="LEFT">decimal</TD></TR>
        <TR><TD ALIGN="LEFT">quantityTotal</TD><TD ALIGN="LEFT">int</TD></TR>
        <TR><TD ALIGN="LEFT">quantityAvailable</TD><TD ALIGN="LEFT">int (decrements on order)</TD></TR>
        <TR><TD ALIGN="LEFT">startTime, endTime</TD><TD ALIGN="LEFT">pickup window</TD></TR>
        <TR><TD ALIGN="LEFT">status</TD><TD ALIGN="LEFT">active/sold_out/expired…</TD></TR>
        <TR><TD ALIGN="LEFT">version</TD><TD ALIGN="LEFT">optimistic lock (anti-oversell)</TD></TR>
        <TR><TD ALIGN="LEFT">businessPartner_id</TD><TD ALIGN="LEFT">FK</TD></TR>
        </TABLE>>]

    Order [label=<
        <TABLE BORDER="0" CELLBORDER="1" CELLSPACING="0" CELLPADDING="5" BGCOLOR="#E1BEE7">
        <TR><TD COLSPAN="2" BGCOLOR="#6A1B9A"><FONT COLOR="white"><B>order</B></FONT></TD></TR>
        <TR><TD ALIGN="LEFT"><B>id</B> (INT, PK)</TD><TD ALIGN="LEFT">auto-increment</TD></TR>
        <TR><TD ALIGN="LEFT">status</TD><TD ALIGN="LEFT">pending/confirmed/…</TD></TR>
        <TR><TD ALIGN="LEFT">subtotal, deliveryFee</TD><TD ALIGN="LEFT">decimal</TD></TR>
        <TR><TD ALIGN="LEFT">deliveryAddressSnapshot</TD><TD ALIGN="LEFT">plain text copy</TD></TR>
        <TR><TD ALIGN="LEFT">estimatedDeliveryTime</TD><TD ALIGN="LEFT">datetime</TD></TR>
        <TR><TD ALIGN="LEFT">completedAt, cancelledAt</TD><TD ALIGN="LEFT">timestamps</TD></TR>
        <TR><TD ALIGN="LEFT">user_id, businessPartner_id</TD><TD ALIGN="LEFT">FK</TD></TR>
        </TABLE>>]

    OrderItem [label=<
        <TABLE BORDER="0" CELLBORDER="1" CELLSPACING="0" CELLPADDING="5" BGCOLOR="#F3E5F5">
        <TR><TD COLSPAN="2" BGCOLOR="#7B1FA2"><FONT COLOR="white"><B>order_item</B></FONT></TD></TR>
        <TR><TD ALIGN="LEFT"><B>id</B> (INT, PK)</TD><TD ALIGN="LEFT">auto-increment</TD></TR>
        <TR><TD ALIGN="LEFT">quantity</TD><TD ALIGN="LEFT">int</TD></TR>
        <TR><TD ALIGN="LEFT">unitPrice</TD><TD ALIGN="LEFT">price snapshot at order time</TD></TR>
        <TR><TD ALIGN="LEFT">totalPrice</TD><TD ALIGN="LEFT">quantity x unitPrice</TD></TR>
        <TR><TD ALIGN="LEFT">foodOffer_id, order_id</TD><TD ALIGN="LEFT">FK</TD></TR>
        </TABLE>>]

    Address [label=<
        <TABLE BORDER="0" CELLBORDER="1" CELLSPACING="0" CELLPADDING="5" BGCOLOR="#FFF9C4">
        <TR><TD COLSPAN="2" BGCOLOR="#F57F17"><FONT COLOR="white"><B>address</B></FONT></TD></TR>
        <TR><TD ALIGN="LEFT"><B>id</B> (INT, PK)</TD><TD ALIGN="LEFT">auto-increment</TD></TR>
        <TR><TD ALIGN="LEFT">street, city, postalCode</TD><TD ALIGN="LEFT">string</TD></TR>
        <TR><TD ALIGN="LEFT">latitude, longitude</TD><TD ALIGN="LEFT">for delivery ETA</TD></TR>
        <TR><TD ALIGN="LEFT">user_id, businessPartner_id</TD><TD ALIGN="LEFT">FK</TD></TR>
        </TABLE>>]

    Review [label=<
        <TABLE BORDER="0" CELLBORDER="1" CELLSPACING="0" CELLPADDING="5" BGCOLOR="#FFCDD2">
        <TR><TD COLSPAN="2" BGCOLOR="#C62828"><FONT COLOR="white"><B>review</B></FONT></TD></TR>
        <TR><TD ALIGN="LEFT"><B>id</B> (INT, PK)</TD><TD ALIGN="LEFT">auto-increment</TD></TR>
        <TR><TD ALIGN="LEFT">rating (1-5)</TD><TD ALIGN="LEFT">int</TD></TR>
        <TR><TD ALIGN="LEFT">comment</TD><TD ALIGN="LEFT">text</TD></TR>
        <TR><TD ALIGN="LEFT">user_id, businessPartner_id</TD><TD ALIGN="LEFT">FK</TD></TR>
        </TABLE>>]

    DeviceToken [label=<
        <TABLE BORDER="0" CELLBORDER="1" CELLSPACING="0" CELLPADDING="5" BGCOLOR="#B3E5FC">
        <TR><TD COLSPAN="2" BGCOLOR="#0288D1"><FONT COLOR="white"><B>device_token</B></FONT></TD></TR>
        <TR><TD ALIGN="LEFT"><B>id</B> (INT, PK)</TD><TD ALIGN="LEFT">auto-increment</TD></TR>
        <TR><TD ALIGN="LEFT">token</TD><TD ALIGN="LEFT">FCM device token</TD></TR>
        <TR><TD ALIGN="LEFT">platform</TD><TD ALIGN="LEFT">ios / android</TD></TR>
        <TR><TD ALIGN="LEFT">user_id</TD><TD ALIGN="LEFT">FK</TD></TR>
        </TABLE>>]

    User            -> BusinessPartner [label="works at\n(nullable)" color="#2E7D32" fontcolor="#2E7D32"]
    BusinessPartner -> FoodOffer       [label="creates" color="#E65100" fontcolor="#E65100"]
    FoodOffer       -> OrderItem       [label="in" color="#7B1FA2" fontcolor="#7B1FA2"]
    OrderItem       -> Order           [label="part of" color="#6A1B9A" fontcolor="#6A1B9A"]
    Order           -> User            [label="placed by" color="#1565C0" fontcolor="#1565C0" style=dashed]
    Order           -> BusinessPartner [label="placed at" color="#2E7D32" fontcolor="#2E7D32" style=dashed]
    Address         -> User            [label="belongs to" color="#F57F17" fontcolor="#F57F17"]
    Review          -> BusinessPartner [label="for" color="#C62828" fontcolor="#C62828"]
    DeviceToken     -> User            [label="owned by" color="#0288D1" fontcolor="#0288D1"]
}
""")


def diag_food_offer_lifecycle():
    return render_dot("food_offer_lifecycle", """
digraph FoodOfferLifecycle {
    graph [rankdir=LR fontname="Helvetica" bgcolor="#FAFAFA" pad=0.6 nodesep=0.8 ranksep=1.1]
    node  [fontname="Helvetica" fontsize=12 style="filled,rounded" penwidth=2.5]
    edge  [fontname="Helvetica" fontsize=10 penwidth=2 arrowsize=1.1]

    Create    [label="Business creates\nFood Offer" shape=box fillcolor="#ECEFF1" color="#455A64"]
    Scheduled [label="SCHEDULED\nstartTime not yet reached" shape=box fillcolor="#B3E5FC" color="#0288D1" fontcolor="#01579B" fontname="Helvetica Bold"]
    Active    [label="ACTIVE\nCustomers can order" shape=box fillcolor="#DCEDC8" color="#2E7D32" fontcolor="#1B5E20" fontname="Helvetica Bold" fontsize=13]
    SoldOut   [label="SOLD OUT\nquantityAvailable = 0" shape=box fillcolor="#FFCDD2" color="#C62828" fontcolor="#B71C1C" fontname="Helvetica Bold"]
    Expired   [label="EXPIRED\nendTime has passed" shape=box fillcolor="#FFF9C4" color="#F57F17" fontcolor="#E65100" fontname="Helvetica Bold"]
    Hidden    [label="HIDDEN\nTemporarily invisible" shape=box fillcolor="#ECEFF1" color="#546E7A" fontname="Helvetica Bold"]
    Cancelled [label="CANCELLED\nPermanently stopped" shape=box fillcolor="#FFCDD2" color="#B71C1C" fontcolor="#B71C1C" fontname="Helvetica Bold"]

    Create    -> Active    [label="startTime now" color="#2E7D32" fontcolor="#2E7D32"]
    Create    -> Scheduled [label="startTime in future" color="#0288D1" fontcolor="#0288D1"]
    Scheduled -> Active    [label="startTime reached" color="#2E7D32" fontcolor="#2E7D32"]
    Active    -> SoldOut   [label="qty = 0" color="#C62828" fontcolor="#C62828"]
    Active    -> Expired   [label="endTime passed" color="#F57F17" fontcolor="#F57F17"]
    Active    -> Hidden    [label="business hides" color="#546E7A" fontcolor="#546E7A"]
    Active    -> Cancelled [label="permanently cancelled" color="#B71C1C" fontcolor="#B71C1C"]
    Hidden    -> Active    [label="re-show" color="#2E7D32" fontcolor="#2E7D32"]
    SoldOut   -> Active    [label="order cancelled\n(stock restored)" style=dashed color="#2E7D32" fontcolor="#2E7D32"]
}
""")


def diag_order_lifecycle():
    return render_dot("order_lifecycle", """
digraph OrderLifecycle {
    graph [rankdir=LR fontname="Helvetica" bgcolor="#FAFAFA" pad=0.7 nodesep=0.9 ranksep=1.3]
    node  [fontname="Helvetica" fontsize=12 style="filled,rounded" penwidth=2.5]
    edge  [fontname="Helvetica" fontsize=10 penwidth=2 arrowsize=1.1]

    Place     [label="Customer\nplaces order" shape=box fillcolor="#ECEFF1" color="#455A64"]
    Pending   [label="PENDING\nWaiting for business decision" shape=box fillcolor="#FFF9C4" color="#F57F17" fontcolor="#E65100" fontname="Helvetica Bold" fontsize=13]
    Confirmed [label="CONFIRMED\nBusiness accepted" shape=box fillcolor="#DCEDC8" color="#2E7D32" fontcolor="#1B5E20" fontname="Helvetica Bold" fontsize=13]
    Ready     [label="READY FOR PICKUP\nFood ready" shape=box fillcolor="#C8E6C9" color="#388E3C" fontcolor="#1B5E20" fontname="Helvetica Bold" fontsize=13]
    Completed [label="COMPLETED\nOrder handed over" shape=box fillcolor="#A5D6A7" color="#1B5E20" fontcolor="#1B5E20" fontname="Helvetica Bold" fontsize=13]
    Cancelled [label="CANCELLED\nRejected / cancelled\nStock restored" shape=box fillcolor="#FFCDD2" color="#C62828" fontcolor="#B71C1C" fontname="Helvetica Bold" fontsize=13]

    NewTab  [label="NEW Tab\n(Business app)"    shape=box style="dashed,rounded" fillcolor="#FFF9C4" color="#F57F17" fontsize=11]
    ActTab  [label="ACTIVE Tab\n(Business app)" shape=box style="dashed,rounded" fillcolor="#DCEDC8" color="#2E7D32" fontsize=11]
    DoneTab [label="DONE Tab\n(Business app)"   shape=box style="dashed,rounded" fillcolor="#ECEFF1" color="#455A64" fontsize=11]

    Place    -> Pending
    Pending  -> Confirmed [label="Business accepts" color="#2E7D32" fontcolor="#2E7D32" penwidth=2.5]
    Pending  -> Cancelled [label="Business rejects" color="#C62828" fontcolor="#C62828" penwidth=2.5]
    Confirmed -> Ready    [label="Food ready" color="#2E7D32" fontcolor="#2E7D32" penwidth=2.5]
    Confirmed -> Pending  [label="undo" style=dashed color="#F57F17" fontcolor="#F57F17"]
    Ready    -> Completed [label="Delivered" color="#1B5E20" fontcolor="#1B5E20" penwidth=2.5]
    Ready    -> Confirmed [label="undo" style=dashed color="#F57F17" fontcolor="#F57F17"]
    Confirmed -> Cancelled [label="cancel" style=dashed color="#C62828" fontcolor="#C62828"]
    Ready    -> Cancelled  [label="cancel" style=dashed color="#C62828" fontcolor="#C62828"]

    Pending   -> NewTab  [style=dotted color="#F57F17"]
    Confirmed -> ActTab  [style=dotted color="#2E7D32"]
    Ready     -> ActTab  [style=dotted color="#2E7D32"]
    Completed -> DoneTab [style=dotted color="#455A64"]
    Cancelled -> DoneTab [style=dotted color="#455A64"]
}
""")


def diag_order_placement():
    return render_dot("order_placement", """
digraph OrderPlacement {
    graph [rankdir=TB fontname="Helvetica" splines=ortho bgcolor="#FAFAFA" pad=0.6 nodesep=0.5 ranksep=0.7]
    node  [fontname="Helvetica" fontsize=12 style="filled,rounded" penwidth=2]
    edge  [fontname="Helvetica" fontsize=10 penwidth=1.8]

    Start  [label="POST /api/orders  {businessPartner, orderItems, deliveryAddress}" shape=box fillcolor="#BBDEFB" color="#1565C0" fontcolor="#0D47A1" fontname="Helvetica Bold"]
    S1     [label="Step 1: Validate Stock\nLoad each food offer from DB\nCheck quantityAvailable >= requested qty\nSnapshot unitPrice from DB\nDecrement quantityAvailable" shape=box fillcolor="#FFE0B2" color="#E65100" fontcolor="#BF360C"]
    StockFail [label="422 Unprocessable\nNot enough stock" shape=box fillcolor="#FFCDD2" color="#C62828" fontcolor="#B71C1C"]
    S2     [label="Step 2: Calculate Subtotal\nsum(quantity x unitPrice) server-side" shape=box fillcolor="#FFE0B2" color="#E65100" fontcolor="#BF360C"]
    S3     [label="Step 3: Snapshot Delivery Address\nSave plain text copy of address\n(order history survives address changes)" shape=box fillcolor="#FFF9C4" color="#F57F17" fontcolor="#E65100"]
    S4     [label="Step 4: Estimate Delivery Time\nbusiness lat/lng to delivery lat/lng" shape=box fillcolor="#FFF9C4" color="#F57F17" fontcolor="#E65100"]
    S5     [label="Step 5: Save to MySQL\nOrder + OrderItems persisted" shape=box fillcolor="#FFE0B2" color="#E65100" fontcolor="#BF360C"]
    S6     [label="Step 6: Push Notification\nSend FCM to all business staff devices" shape=box fillcolor="#B3E5FC" color="#0288D1" fontcolor="#01579B"]
    Done   [label="201 Created\nOrder appears in customer My Orders" shape=box fillcolor="#DCEDC8" color="#2E7D32" fontcolor="#1B5E20" fontname="Helvetica Bold"]

    Start -> S1
    S1 -> StockFail [label="Qty too high" color="#C62828" fontcolor="#C62828"]
    S1 -> S2 [label="Stock OK" color="#2E7D32" fontcolor="#2E7D32"]
    S2 -> S3 -> S4 -> S5 -> S6 -> Done
}
""")


def diag_customer_journey():
    return render_dot("customer_journey", """
digraph CustomerJourney {
    graph [rankdir=TB fontname="Helvetica" splines=ortho bgcolor="#FAFAFA" pad=0.6 nodesep=0.5 ranksep=0.75]
    node  [fontname="Helvetica" fontsize=12 style="filled,rounded" penwidth=2]
    edge  [fontname="Helvetica" fontsize=10 penwidth=1.8]

    Home      [label="Home Screen\nBrowse food offers\n(active + not expired)" shape=box fillcolor="#BBDEFB" color="#1565C0" fontcolor="#0D47A1"]
    Detail    [label="Offer Detail\nPhoto, price, pickup window" shape=box fillcolor="#BBDEFB" color="#1565C0" fontcolor="#0D47A1"]
    BizCheck  [label="Business currently\nactive?" shape=diamond fillcolor="#FFF9C4" color="#F57F17" fontcolor="#E65100"]
    Closed    [label="Dialog: Restaurant Closed\nCannot order" shape=box fillcolor="#FFCDD2" color="#C62828" fontcolor="#B71C1C"]
    Checkout  [label="Checkout Screen\nQuantity, address, notes, price" shape=box fillcolor="#C8E6C9" color="#2E7D32" fontcolor="#1B5E20"]
    Payment   [label="Payment Screen\nConfirm total" shape=box fillcolor="#C8E6C9" color="#2E7D32" fontcolor="#1B5E20"]
    Placed    [label="Order Placed\nAppears in My Orders" shape=box fillcolor="#DCEDC8" color="#2E7D32" fontcolor="#1B5E20" fontname="Helvetica Bold"]
    Track     [label="Track Order\nPending to Confirmed to Done" shape=box fillcolor="#BBDEFB" color="#1565C0" fontcolor="#0D47A1"]

    Home -> Detail
    Detail -> BizCheck [label="Order Now tapped"]
    BizCheck -> Closed   [label="Closed" color="#C62828" fontcolor="#C62828"]
    BizCheck -> Checkout [label="Open"   color="#2E7D32" fontcolor="#2E7D32"]
    Checkout -> Payment -> Placed -> Track
}
""")


def diag_business_dashboard():
    return render_dot("business_dashboard", """
digraph BusinessDashboard {
    graph [rankdir=LR fontname="Helvetica" bgcolor="#FAFAFA" pad=0.6 nodesep=0.6 ranksep=1.1 splines=ortho]
    node  [fontname="Helvetica" fontsize=11 style="filled,rounded" penwidth=2]
    edge  [fontname="Helvetica" fontsize=10 penwidth=1.7]

    Login    [label="Business Login" shape=box fillcolor="#E1BEE7" color="#6A1B9A" fontcolor="#4A148C"]
    Dash     [label="Dashboard\nOpen/Close toggle\nToday stats + alerts" shape=box fillcolor="#C8E6C9" color="#2E7D32" fontcolor="#1B5E20" fontname="Helvetica Bold"]
    Orders   [label="Orders Screen\nNEW | ACTIVE | DONE" shape=box fillcolor="#BBDEFB" color="#1565C0" fontcolor="#0D47A1" fontname="Helvetica Bold"]
    Menu     [label="Menu Screen\nCreate, Edit, Hide offers" shape=box fillcolor="#FFE0B2" color="#E65100" fontcolor="#BF360C"]
    Settings [label="Settings\nProfile, Team, Notifications" shape=box fillcolor="#FFF9C4" color="#F57F17" fontcolor="#E65100"]
    Analytics [label="Analytics\nRevenue, Order history" shape=box fillcolor="#F3E5F5" color="#7B1FA2" fontcolor="#4A148C"]

    NewTab    [label="NEW Tab\nAccept / Reject" shape=box fillcolor="#FFF9C4" color="#F57F17" fontcolor="#E65100"]
    ActiveTab [label="ACTIVE Tab\nAdvance progress" shape=box fillcolor="#DCEDC8" color="#2E7D32" fontcolor="#1B5E20"]
    DoneTab   [label="DONE Tab\nCompleted + Cancelled" shape=box fillcolor="#ECEFF1" color="#455A64"]

    Login -> Dash
    Dash -> Orders    [label="Orders tab"]
    Dash -> Menu      [label="Menu tab"]
    Dash -> Settings
    Dash -> Analytics
    Orders -> NewTab
    Orders -> ActiveTab
    Orders -> DoneTab
}
""")


def diag_api_structure():
    return render_dot("api_structure", """
digraph ApiStructure {
    graph [rankdir=LR fontname="Helvetica" bgcolor="#FAFAFA" pad=0.6 nodesep=0.5 ranksep=1.1]
    node  [fontname="Helvetica" fontsize=11 style="filled,rounded" penwidth=2]
    edge  [fontname="Helvetica" fontsize=10 penwidth=1.5]

    Entity   [label="PHP Entity Class\nwith ApiResource attributes" shape=box fillcolor="#FFE0B2" color="#E65100" fontcolor="#BF360C" fontname="Helvetica Bold"]
    APi      [label="API Platform\nauto-generates REST endpoints" shape=box fillcolor="#C8E6C9" color="#2E7D32" fontcolor="#1B5E20" fontname="Helvetica Bold"]

    GET    [label="GET /api/food_offers\nList with filters + pagination" shape=box fillcolor="#BBDEFB" color="#1565C0" fontcolor="#0D47A1"]
    GETid  [label="GET /api/food_offers/{id}\nSingle item" shape=box fillcolor="#BBDEFB" color="#1565C0" fontcolor="#0D47A1"]
    POST   [label="POST /api/food_offers\nCreate new" shape=box fillcolor="#DCEDC8" color="#2E7D32" fontcolor="#1B5E20"]
    PATCH  [label="PATCH /api/food_offers/{id}\nPartial update (merge-patch+json)" shape=box fillcolor="#FFF9C4" color="#F57F17" fontcolor="#E65100"]
    DELETE [label="DELETE /api/food_offers/{id}" shape=box fillcolor="#FFCDD2" color="#C62828" fontcolor="#B71C1C"]

    Security [label="Security Layer\nJWT validated\nSerialization groups\nQuery extensions auto-filter" shape=box fillcolor="#E1BEE7" color="#6A1B9A" fontcolor="#4A148C"]

    Entity -> APi -> GET
    APi -> GETid
    APi -> POST
    APi -> PATCH
    APi -> DELETE
    APi -> Security [style=dashed color="#6A1B9A" fontcolor="#6A1B9A"]
}
""")


# ─────────────────────────────────────────────────────────────────────────────
# RENDER ALL DIAGRAMS
# ─────────────────────────────────────────────────────────────────────────────

print("Rendering diagrams...")
svgs = {
    "architecture":       diag_architecture(),
    "auth_flow":          diag_auth_flow(),
    "jwt":                diag_jwt_structure(),
    "registration":       diag_registration(),
    "role_routing":       diag_role_routing(),
    "database":           diag_database(),
    "food_offer":         diag_food_offer_lifecycle(),
    "order_lifecycle":    diag_order_lifecycle(),
    "order_placement":    diag_order_placement(),
    "customer_journey":   diag_customer_journey(),
    "business_dashboard": diag_business_dashboard(),
    "api_structure":      diag_api_structure(),
}
print(f"  {len(svgs)} diagrams rendered")


def img(svg_path: pathlib.Path, caption="") -> str:
    """Return an <img> tag pointing to the SVG file via absolute file:// path."""
    cap = f'<p class="diagram-caption">{caption}</p>' if caption else ""
    return f'<div class="diagram-wrap"><img src="{svg_path.resolve()}" />{cap}</div>'


# ─────────────────────────────────────────────────────────────────────────────
# CSS — plain professional text, color only in diagrams / tables / callouts
# ─────────────────────────────────────────────────────────────────────────────

CSS = """
* { box-sizing: border-box; margin: 0; padding: 0; }

body {
    font-family: "Helvetica Neue", Helvetica, Arial, sans-serif;
    font-size: 11pt;
    line-height: 1.8;
    color: #1A1A1A;
    background: #fff;
}

/* ── COVER ──────────────────────────────────────────────── */
.cover {
    width: 100%; min-height: 800px;
    background: linear-gradient(135deg, #1B5E20 0%, #2E7D32 55%, #43A047 100%);
    display: flex; flex-direction: column;
    justify-content: center; align-items: flex-start;
    padding: 90px 100px;
    color: #fff;
    page-break-after: always;
    position: relative; overflow: hidden;
}
.cover::before {
    content: "";
    position: absolute; top: -100px; right: -80px;
    width: 420px; height: 420px; border-radius: 50%;
    background: rgba(255,255,255,0.07);
}
.cover h1 {
    font-size: 54pt; font-weight: 900;
    margin-bottom: 10px; color: #fff;
    background: none; padding: 0; border-radius: 0;
    letter-spacing: -1.5px; position: relative; z-index: 1;
}
.cover .cover-sub  { font-size: 18pt; opacity: .88; margin-bottom: 16px; position: relative; z-index: 1; }
.cover .cover-desc { font-size: 12pt; opacity: .70; max-width: 560px; margin-bottom: 60px; position: relative; z-index: 1; }
.cover-badge {
    display: inline-block;
    background: rgba(255,255,255,0.18);
    border: 1px solid rgba(255,255,255,0.35);
    border-radius: 6px; padding: 4px 13px;
    font-size: 10pt; margin: 3px 4px;
    position: relative; z-index: 1;
}
.cover-meta {
    font-size: 10pt; opacity: .60;
    border-top: 1px solid rgba(255,255,255,0.2);
    padding-top: 20px; margin-top: 20px;
    position: relative; z-index: 1;
}

/* ── TOC ─────────────────────────────────────────────────── */
.toc-page { padding: 70px 90px; page-break-after: always; }
.toc-page h2 { margin-bottom: 32px; }
.toc-item {
    display: flex; align-items: center;
    padding: 9px 0;
    border-bottom: 1px solid #EEE;
    font-size: 11.5pt;
}
.toc-num {
    width: 32px; height: 32px;
    background: #2E7D32; color: #fff; border-radius: 50%;
    display: flex; align-items: center; justify-content: center;
    font-weight: 700; font-size: 10.5pt; margin-right: 14px; flex-shrink: 0;
}
.toc-title { flex: 1; color: #1A1A1A; }
.toc-dots  { flex: 1; border-bottom: 2px dotted #DDD; margin: 0 16px; }
.toc-page-n { color: #999; font-size: 10pt; }

/* ── SECTION PAGE ────────────────────────────────────────── */
.section { page-break-before: always; padding: 60px 90px; }
.section:first-child { page-break-before: avoid; }

/* ── HEADINGS — plain black, minimal ────────────────────── */
h1 {
    font-size: 22pt; font-weight: 900;
    color: #1A1A1A;
    border-bottom: 3px solid #2E7D32;
    padding-bottom: 10px; margin-bottom: 6px;
    margin-top: 0;
}
.section-number {
    display: inline-block;
    background: #2E7D32; color: #fff;
    border-radius: 5px; padding: 1px 9px;
    font-size: 13pt; margin-right: 10px; font-weight: 700;
}
.section-subtitle {
    font-size: 11pt; color: #777;
    margin-bottom: 28px; margin-top: 4px;
    padding-left: 2px; font-style: italic;
}

h2 {
    font-size: 14pt; font-weight: 800;
    color: #1A1A1A;
    margin-top: 30px; margin-bottom: 10px;
    padding-left: 14px;
    border-left: 4px solid #2E7D32;
}

h3 {
    font-size: 12pt; font-weight: 700;
    color: #333;
    margin-top: 20px; margin-bottom: 7px;
    text-transform: uppercase; letter-spacing: 0.5px;
}

/* ── DIAGRAM BOX ─────────────────────────────────────────── */
.diagram-wrap {
    background: #F8FBF8;
    border: 1.5px solid #C8E6C9;
    border-radius: 10px;
    padding: 20px 16px;
    margin: 18px 0 26px;
    text-align: center;
    page-break-inside: avoid;
}
.diagram-wrap img {
    max-width: 100%;
    height: auto;
}
.diagram-caption {
    font-size: 9pt; color: #888;
    margin-top: 8px; font-style: italic;
}

/* ── BODY TEXT ───────────────────────────────────────────── */
p { margin-bottom: 12px; color: #1A1A1A; }

/* ── CODE ─────────────────────────────────────────────────── */
pre {
    background: #1E1E1E;
    color: #D4D4D4;
    border-radius: 8px;
    padding: 16px 20px;
    margin: 14px 0;
    font-family: "Courier New", Courier, monospace;
    font-size: 9pt;
    line-height: 1.6;
    white-space: pre;
    page-break-inside: avoid;
}
code {
    font-family: "Courier New", Courier, monospace;
    font-size: 9.5pt;
    background: #F5F5F5;
    border: 1px solid #DDD;
    border-radius: 3px;
    padding: 1px 6px;
    color: #333;
}

/* ── TABLES — header colored, body plain ────────────────── */
table {
    width: 100%; border-collapse: collapse;
    margin: 14px 0; font-size: 10pt;
    page-break-inside: avoid;
}
th {
    background: #2E7D32; color: #fff;
    padding: 10px 14px; text-align: left;
    font-weight: 700; font-size: 9.5pt;
}
td {
    padding: 8px 14px;
    border-bottom: 1px solid #EBEBEB;
    vertical-align: top;
    color: #1A1A1A;
}
tr:nth-child(even) td { background: #F9F9F9; }
tr:last-child td { border-bottom: none; }

/* ── CALLOUT BOXES ───────────────────────────────────────── */
.callout {
    border-radius: 8px; padding: 13px 18px;
    margin: 14px 0; page-break-inside: avoid;
}
.callout-info    { background: #E3F2FD; border-left: 4px solid #1565C0; color: #0D47A1; }
.callout-success { background: #E8F5E9; border-left: 4px solid #2E7D32; color: #1B5E20; }
.callout-warning { background: #FFF8E1; border-left: 4px solid #F57F17; color: #E65100; }
.callout-tip     { background: #F3E5F5; border-left: 4px solid #6A1B9A; color: #4A148C; }

/* ── LISTS ───────────────────────────────────────────────── */
ul, ol { margin: 10px 0 12px 24px; }
li { margin-bottom: 5px; line-height: 1.7; color: #1A1A1A; }

hr { border: none; border-top: 1px solid #DDD; margin: 26px 0; }

strong { font-weight: 700; }
em { color: #555; }
"""


def section(num, title, subtitle, body):
    return f"""
<div class="section">
<h1><span class="section-number">{num}</span> {title}</h1>
<p class="section-subtitle">{subtitle}</p>
{body}
</div>"""


def callout(kind, text):
    icons = {"info": "ℹ️ ", "success": "✅ ", "warning": "⚠️ ", "tip": "💡 "}
    return f'<div class="callout callout-{kind}">{icons.get(kind,"")}{text}</div>'


# ─────────────────────────────────────────────────────────────────────────────
# SECTION BODIES
# ─────────────────────────────────────────────────────────────────────────────

sections_html = []

# ── 1. Big Picture ─────────────────────────────────────────────────────────
sections_html.append(section("1", "Big Picture", "How all parts of the system talk to each other — step by step", f"""
{img(svgs["architecture"], "System Architecture — numbered arrows show exactly what happens and in what order")}

<h2>How to Read This Diagram</h2>
<p>
Every arrow in the diagram above has a numbered step and a plain-English label.
The steps follow the order of what really happens behind the scenes, from the moment you
open the app to the moment data appears on your screen.
There are <strong>two distinct flows</strong> — a login flow (happens once) and a data flow
(happens every time you tap something).
</p>

<h2>The Arrow Colors — What Each Color Means</h2>
<table>
<tr><th>Color</th><th>Meaning</th><th>Which arrows</th></tr>
<tr><td>Purple</td><td>Security / Login flow — proving who you are</td><td>Steps 1, 2, and the background check in Step 4</td></tr>
<tr><td>Green</td><td>Data request flow — asking for or sending data</td><td>Step 3 (app → Symfony)</td></tr>
<tr><td>Orange</td><td>Database access — reading or writing to MySQL</td><td>Step 5 (Symfony → MySQL)</td></tr>
<tr><td>Blue</td><td>Push notification — alerting business staff</td><td>Step 6 (Symfony → Firebase)</td></tr>
</table>

<h2>Step-by-Step: What Happens When You Use the App</h2>

<h3>Step 1 — You log in (purple arrow: Phone → Keycloak)</h3>
<p>
When you open the app and tap "Log In", the app sends your <strong>email address and password</strong>
to <strong>Keycloak</strong> — a dedicated security service running on the server.
Keycloak is like a security guard at the front door: its only job is to check passwords
and decide who gets in.
The app never sends your password anywhere else — only to Keycloak, over an encrypted HTTPS connection.
</p>

<h3>Step 2 — You receive a digital key (purple arrow: Keycloak → Phone)</h3>
<p>
If your password is correct, Keycloak creates a small digital key called a <strong>JWT token</strong>
(JSON Web Token) and sends it back to the app.
Think of it like a wristband you receive at the entrance of a venue — it proves you passed the
security check, so you don't have to show your passport at every door inside.
</p>
<p>
The JWT token contains:
</p>
<ul>
  <li>Who you are (your unique ID and email)</li>
  <li>What role you have (customer, business partner, or admin)</li>
  <li>When the key expires (after 5 minutes — the app renews it automatically)</li>
</ul>
<p>
The app stores this token securely in the phone's encrypted keychain — it is never stored
in a regular file or shared preferences.
</p>

<h3>Step 3 — Every request carries the digital key (green arrow: Phone → Symfony)</h3>
<p>
From this point on, every time the app needs data — loading food offers, placing an order,
viewing order history — it sends the request to the <strong>Symfony API</strong> (the main
server) and <em>attaches the JWT token</em> to the request.
This happens automatically in the background; the user never sees it.
It is the equivalent of showing your wristband every time you walk through a door inside the venue.
</p>

{callout("info", "<strong>What is Symfony?</strong> Symfony is the server-side application that contains all of the business logic — it knows the rules for placing orders, calculating prices, checking stock, and managing users. It does not handle passwords or login directly; it trusts Keycloak for that.")}

<h3>Step 4 — Background security check (dashed purple arrow: Symfony → Keycloak)</h3>
<p>
When Symfony receives a request, it does a quick <strong>invisible background check</strong>:
it reads the JWT token attached to the request and verifies that the digital signature
is genuine — it was really issued by Keycloak, not forged by someone.
This check happens in milliseconds without any extra round-trip to Keycloak
(Keycloak's public key is cached on the Symfony server).
If the token is invalid, expired, or tampered with, the request is rejected immediately
with a "401 Unauthorized" response.
</p>

<h3>Step 5 — Read or write data (orange arrow: Symfony → MySQL)</h3>
<p>
Once the token is verified and Symfony knows who you are, it talks to the
<strong>MySQL database</strong> to get or save the data you need.
For example:
</p>
<ul>
  <li>Customer loads food offers → Symfony asks MySQL for all active offers</li>
  <li>Business partner accepts an order → Symfony updates the order's status in MySQL</li>
  <li>Admin views all users → Symfony fetches the full user list from MySQL</li>
</ul>
<p>
All persistent data — every user account, every order, every food offer, every address — lives in MySQL.
</p>

<h3>Step 6 — Push notification to staff (blue arrow: Symfony → Firebase)</h3>
<p>
When a customer places a new order, Symfony does one extra thing after saving the order to MySQL:
it sends a <strong>push notification</strong> to the business partner's staff phones via
<strong>Firebase FCM</strong> (Google's notification service).
This is what makes the order appear instantly on the business partner's screen with the
"New order arrived!" alert, without the business partner having to manually refresh the page.
</p>

<h2>What Each Layer Does — Summary</h2>
<table>
<tr><th>Layer</th><th>Technology</th><th>Simple Explanation</th></tr>
<tr><td>Mobile App</td><td>Flutter</td><td>The app users see and interact with. Comes in three versions: Customer, Business, and Admin — all in one codebase.</td></tr>
<tr><td>Security Guard</td><td>Keycloak</td><td>Checks your password when you log in. Issues a temporary digital key (JWT). Never involved again until the key expires.</td></tr>
<tr><td>API / Brain</td><td>Symfony + API Platform</td><td>Does all the real work: manages orders, offers, prices, stock, addresses. Trusts the digital key from Keycloak.</td></tr>
<tr><td>Storage</td><td>MySQL</td><td>Stores everything permanently: every user, order, offer, address, review. Data lives here forever.</td></tr>
<tr><td>Push Alerts</td><td>Firebase FCM</td><td>Delivers instant push notifications to business staff phones when a new customer order arrives.</td></tr>
<tr><td>Infrastructure</td><td>Docker</td><td>Keycloak and MySQL each run in their own isolated container on the server. Easy to update and maintain separately.</td></tr>
</table>

{callout("success", "<strong>Real example:</strong> A customer opens the app and taps 'Browse Food'. Step 1+2 already happened at login. So now: Step 3 — the app asks Symfony 'give me all active food offers', attaching the JWT token. Step 4 — Symfony silently verifies the token (valid). Step 5 — Symfony asks MySQL for active offers and returns them to the app. The customer sees the list in under a second.")}
"""))

# ── 2. Authentication ───────────────────────────────────────────────────────
sections_html.append(section("2", "Authentication — Keycloak & JWT", "How the app proves who you are on every single request", f"""
{img(svgs["auth_flow"], "Authentication Flow — token request, validation, automatic refresh, and forced logout on failure")}

<h2>What is Keycloak?</h2>
<p>Keycloak is a dedicated login service — think of it as the same role as "Sign in with Google". It handles passwords, sessions, and token signing so the backend never needs to store or verify passwords directly. It runs on our own server inside Docker.</p>

<h2>What is a JWT Token?</h2>
{img(svgs["jwt"], "JWT Structure — three Base64-encoded parts: header (algorithm), payload (identity + roles), and signature (tamper-proof seal)")}

<p>A JWT is a small encoded text string passed with every API request. It has three dot-separated sections:</p>
<ul>
  <li><strong>Header</strong> — which algorithm signed it (RS256)</li>
  <li><strong>Payload</strong> — your identity: UUID, email, roles, expiry time</li>
  <li><strong>Signature</strong> — Keycloak's cryptographic seal; any tampering breaks this</li>
</ul>

{callout("warning", "<strong>Token Expiry:</strong> Access tokens expire after <strong>5 minutes</strong>. The app automatically uses the refresh token (valid for hours) to get a new access token silently — the user never sees a re-login prompt unless the refresh token also expires.")}

<h2>Token Storage</h2>
<table>
<tr><th>Key</th><th>Content</th><th>Lifetime</th><th>Storage</th></tr>
<tr><td><code>kc_access_token</code></td><td>JWT sent with every API request</td><td>~5 minutes</td><td>iOS Keychain / Android Keystore (encrypted)</td></tr>
<tr><td><code>kc_refresh_token</code></td><td>Used to get a new access token silently</td><td>Hours</td><td>Same encrypted storage</td></tr>
<tr><td><code>kc_id_token</code></td><td>Contains user profile info</td><td>~5 minutes</td><td>Same encrypted storage</td></tr>
</table>

{callout("success", "Tokens are stored in <code>FlutterSecureStorage</code>, which uses the device's native encrypted keychain. They are never stored in plain shared preferences or local files.")}

<h2>Auth Interceptor — Automatic Token Management</h2>
<p>A Dio HTTP interceptor runs automatically before every API call. Developers never manually attach tokens. The interceptor:</p>
<ol>
  <li>Reads the stored access token</li>
  <li>Checks if it will expire in the next 30 seconds</li>
  <li>If yes, silently calls Keycloak with the refresh token to get a new one</li>
  <li>Attaches the valid token to the request header</li>
  <li>If refresh fails — clears tokens and redirects to Login screen</li>
</ol>
"""))

# ── 3. Registration & Login ─────────────────────────────────────────────────
sections_html.append(section("3", "Registration & Login", "How new accounts are created and how users reach their dashboard", f"""
<h2>Registration Flow</h2>
{img(svgs["registration"], "Registration — 4-step process across Keycloak + MySQL")}

{callout("tip", "<strong>Why two systems?</strong> Keycloak owns authentication (passwords, sessions). MySQL owns business data (orders, offers, addresses). When registering, both must be updated in one request — the Symfony backend coordinates this automatically.")}

<h2>What Happens When a Business Registers?</h2>
<p>When <code>accountType = business</code>, the registration creates two database records:</p>
<table>
<tr><th>Record</th><th>Initial Values</th></tr>
<tr><td>User</td><td>roles: [ROLE_BUSINESS_PARTNER], linked to the BusinessPartner</td></tr>
<tr><td>BusinessPartner</td><td>kycStatus: <strong>pending</strong>, isActive: true, deliveryFee: 0.00</td></tr>
</table>
{callout("warning", "<strong>KYC Gate:</strong> A business with kycStatus = 'pending' cannot publish food offers. An Admin must approve the account first.")}

<h2>Role-Based Routing After Login</h2>
{img(svgs["role_routing"], "Role-Based Routing — JWT roles determine which dashboard opens after login")}

<table>
<tr><th>Role</th><th>Destination</th><th>What They See</th></tr>
<tr><td>ROLE_ADMIN</td><td>Admin Dashboard</td><td>Platform-wide stats, all users, all orders, KYC approval</td></tr>
<tr><td>ROLE_BUSINESS_PARTNER</td><td>Business Dashboard</td><td>Their orders, menu management, earnings</td></tr>
<tr><td>ROLE_MEMBER</td><td>Business Dashboard</td><td>Same as business partner (staff account)</td></tr>
<tr><td>ROLE_USER</td><td>Customer App</td><td>Browse offers, place orders, favorites</td></tr>
</table>
"""))

# ── 4. Database ──────────────────────────────────────────────────────────────
sections_html.append(section("4", "Database Structure", "All tables, their relationships, and key design decisions", f"""
{img(svgs["database"], "Entity-Relationship Diagram — every table is a coloured box; arrows between boxes show how tables connect to each other")}

<h2>How to Read This Diagram</h2>
<p>
Each <strong>coloured box</strong> is one database table. The table name is in the header row.
The rows below list the columns stored in that table.
<strong>Arrows between boxes</strong> show a relationship — for example, the arrow from
<em>order</em> to <em>user</em> means "this order belongs to that user".
An arrow with a dashed line means the relationship is optional (not always set).
</p>

<h2>A Real Example — What Happens When Maria Orders a Sushi Bag</h2>
<p>Let's trace exactly which database records are created or updated when a customer named
<strong>Maria</strong> orders a "Sushi Bag" from <strong>Mario's Bistro</strong>:</p>
<ol>
  <li><strong>user table</strong> — Maria's row already exists (she registered earlier). Her row has <code>email=maria@mail.com</code>, <code>roles=["ROLE_USER"]</code>, and <code>businessPartner_id=NULL</code> (she's a customer, not a business).</li>
  <li><strong>business_partner table</strong> — Mario's Bistro has a row with <code>businessName="Mario's Bistro"</code>, <code>isActive=true</code>, <code>kycStatus="approved"</code>, <code>deliveryFee=2.50</code>.</li>
  <li><strong>food_offer table</strong> — The "Sushi Bag" has a row: <code>title="Sushi Bag"</code>, <code>price=5.99</code>, <code>quantityAvailable=3</code>, <code>status=active</code>. When Maria orders 1 bag, <code>quantityAvailable</code> drops to <code>2</code>.</li>
  <li><strong>order table</strong> — A new row is created: <code>status=pending</code>, <code>subtotal=5.99</code>, <code>deliveryFee=2.50</code>, <code>deliveryAddressSnapshot="Karl-Marx-Str. 12, 12043 Berlin"</code> (a text copy, so the address is never lost even if Maria later deletes it), <code>user_id=Maria's id</code>, <code>businessPartner_id=Mario's id</code>.</li>
  <li><strong>order_item table</strong> — One row is created: <code>quantity=1</code>, <code>unitPrice=5.99</code> (copied from the food offer at this exact moment — not a live link), <code>totalPrice=5.99</code>.</li>
</ol>

{callout("success", "<strong>Why is the price copied?</strong> If Mario later changes the Sushi Bag price to €7.99, Maria's old order still correctly shows €5.99 — because we saved the price at the time she ordered. Just like a paper receipt that shows what you paid, not what it costs today.")}

<h2>Table-by-Table Explanation</h2>

<h3>user — every person who uses the app</h3>
<p>Stores both customers and business staff. The <code>roles</code> column (a JSON list) says what
the person can do. The <code>businessPartner_id</code> column is empty for regular customers
and filled in for restaurant staff.</p>
<table>
<tr><th>Column</th><th>Example value</th><th>What it means</th></tr>
<tr><td>uuid</td><td>550e8400-e29b-…</td><td>Public unique ID — used in all API responses instead of the raw integer id</td></tr>
<tr><td>email</td><td>maria@mail.com</td><td>Unique — also used to match with Keycloak login</td></tr>
<tr><td>roles</td><td>["ROLE_USER"]</td><td>Controls which dashboard the user sees after login</td></tr>
<tr><td>businessPartner_id</td><td>NULL / 7</td><td>NULL = regular customer. A number = this person works at that restaurant</td></tr>
</table>

<h3>business_partner — each restaurant or shop</h3>
<p>One row per business. <code>kycStatus</code> acts as a gate — the admin must approve a new
business before it can publish offers. <code>isActive</code> is the open/closed toggle on
the business dashboard.</p>
<table>
<tr><th>Column</th><th>Example value</th><th>What it means</th></tr>
<tr><td>kycStatus</td><td>pending / approved / rejected</td><td>pending = waiting for admin approval; only approved businesses can publish food offers</td></tr>
<tr><td>isActive</td><td>true / false</td><td>false = restaurant is closed; their offers disappear from the customer's home screen</td></tr>
<tr><td>deliveryFee</td><td>2.50</td><td>Added to every order total placed with this business</td></tr>
</table>

<h3>food_offer — a surplus food bag listing</h3>
<p>Each "bag" a business publishes is one row. <code>quantityAvailable</code> decreases as
customers order. <code>startTime</code> and <code>endTime</code> define the pickup window.
The <code>version</code> column prevents two customers from buying the last bag at the
exact same time (optimistic lock).</p>
<table>
<tr><th>Column</th><th>Example value</th><th>What it means</th></tr>
<tr><td>quantityAvailable</td><td>3 → 2 → 1 → 0</td><td>Decrements with each order; when it hits 0, the offer shows as "sold out"</td></tr>
<tr><td>startTime / endTime</td><td>18:00 – 20:00</td><td>The window when customers can pick up. After endTime the offer shows as "expired"</td></tr>
<tr><td>status</td><td>active</td><td>Raw value stored in DB. The API computes the real status at runtime (may return "sold_out" or "expired" instead)</td></tr>
<tr><td>version</td><td>1, 2, 3…</td><td>Increases on every update. If two requests try to update simultaneously, the second one is rejected — preventing overselling</td></tr>
</table>

<h3>order + order_item — the customer's purchase</h3>
<p>One <em>order</em> row per purchase. One <em>order_item</em> row per food offer in that purchase.
For example, if Maria orders 2 Sushi Bags and 1 Bakery Bag in the same checkout, there is
1 order row and 2 order_item rows.</p>
<table>
<tr><th>Column</th><th>Example value</th><th>What it means</th></tr>
<tr><td>status</td><td>pending → confirmed → completed</td><td>Tracks where the order is in the lifecycle</td></tr>
<tr><td>deliveryAddressSnapshot</td><td>"Karl-Marx-Str. 12, Berlin"</td><td>Plain text copy of the address at order time — never changes even if the customer later deletes their saved address</td></tr>
<tr><td>order_item.unitPrice</td><td>5.99</td><td>Price copied from the food offer at the moment of ordering — immune to future price changes</td></tr>
</table>

<h3>address — delivery and pickup locations</h3>
<p>Stores both customer delivery addresses and business pickup addresses.
<code>latitude</code> and <code>longitude</code> are used to calculate the estimated delivery time.</p>

<h3>review — star ratings</h3>
<p>After receiving an order, a customer can leave a rating (1–5 stars) and a comment.
The business's average rating is calculated on the fly from all their review rows — it is not
stored as a separate column, so it is always up to date.</p>

<h3>device_token — push notification targets</h3>
<p>When the app starts, it registers the phone's FCM token. When a new order arrives, the server
looks up all device tokens belonging to the business staff and sends a push notification to each one.</p>
"""))

# ── 5. API Structure ────────────────────────────────────────────────────────
sections_html.append(section("5", "API Structure", "How Symfony + API Platform exposes REST endpoints and controls data access", f"""
{img(svgs["api_structure"], "API Platform automatically generates REST endpoints from annotated PHP entity classes")}

<h2>What API Platform Does</h2>
<p>API Platform is a Symfony bundle that <strong>automatically generates REST endpoints</strong> from PHP entity classes. Instead of writing a controller for every endpoint, you annotate the entity and it gets full CRUD immediately.</p>

<h2>Available API Resources</h2>
<table>
<tr><th>Resource</th><th>Base URL</th><th>Who Uses It</th></tr>
<tr><td>User</td><td><code>/api/users</code></td><td>Auth, profile management</td></tr>
<tr><td>BusinessPartner</td><td><code>/api/business_partners</code></td><td>Business owners + Admin</td></tr>
<tr><td>FoodOffer</td><td><code>/api/food_offers</code></td><td>Customers (browse) + Business (manage)</td></tr>
<tr><td>Order</td><td><code>/api/orders</code></td><td>Customers (place) + Business (manage)</td></tr>
<tr><td>Address</td><td><code>/api/addresses</code></td><td>Customer delivery addresses</td></tr>
<tr><td>Image</td><td><code>/api/images</code></td><td>All (food photos, avatars)</td></tr>
<tr><td>Review</td><td><code>/api/reviews</code></td><td>Customers write reviews</td></tr>
<tr><td>DeviceToken</td><td><code>/api/device_tokens</code></td><td>App registers for push notifications</td></tr>
</table>

<h2>Custom Endpoints</h2>
<table>
<tr><th>Endpoint</th><th>Method</th><th>Purpose</th></tr>
<tr><td><code>/api/register</code></td><td>POST</td><td>Create user in Keycloak + MySQL in one step</td></tr>
<tr><td><code>/api/users/me</code></td><td>GET</td><td>Get current user's profile + linked business partner</td></tr>
<tr><td><code>/api/orders/{id}/status</code></td><td>PUT</td><td>Change order status with transition validation</td></tr>
<tr><td><code>/api/images/upload</code></td><td>POST</td><td>Upload a food offer photo or avatar</td></tr>
<tr><td><code>/api/favorite_offers/{id}</code></td><td>POST/DELETE</td><td>Save or remove a saved food offer</td></tr>
</table>

<h2>Automatic Query Filtering (Doctrine Extensions)</h2>
{callout("tip", "These filters run automatically on every database query — the client never needs to pass any parameter. They ensure users can only see data they are allowed to see.")}
<table>
<tr><th>Extension</th><th>What It Does</th></tr>
<tr><td>CurrentUserExtension</td><td>Customers only see their own orders — GET /api/orders returns only their orders</td></tr>
<tr><td>OrderBusinessPartnerExtension</td><td>Business staff only see orders placed at their restaurant</td></tr>
<tr><td>OrderExtension</td><td>Orders are always sorted newest-first by default</td></tr>
</table>

<h2>Serialization Groups — Who Sees What</h2>
<p>Each API operation uses a named group to control which fields are included in the response:</p>
<pre>GET /api/food_offers       → group: foodOffer:collection:get
GET /api/food_offers/7     → group: foodOffer:item:get
POST /api/food_offers      → group: foodOffer:item:post
PATCH /api/food_offers/7   → group: foodOffer:item:patch</pre>
<p>Banking details, password hashes, and internal IDs are excluded from public groups automatically.</p>
"""))

# ── 6. Food Offer Lifecycle ─────────────────────────────────────────────────
sections_html.append(section("6", "Food Offer Lifecycle", "How a surplus food bag goes from creation to sold-out, expired, or cancelled", f"""
{img(svgs["food_offer"], "Food Offer Status Flow — each box is a state the offer can be in; arrows show what causes the transition")}

<h2>How to Read This Diagram</h2>
<p>
Each <strong>box</strong> is a status the food offer can be in at any given moment.
<strong>Arrows</strong> show what event moves the offer from one status to another.
Solid arrows are automatic (the system does it). The dashed arrow (Sold Out → Active) is
exceptional — it only happens if an order that used that stock gets cancelled.
</p>

<h2>Color Legend</h2>
<table>
<tr><th>Color</th><th>Status</th><th>Meaning</th></tr>
<tr><td>Green</td><td>ACTIVE</td><td>Customers can see this offer and place orders right now</td></tr>
<tr><td>Blue</td><td>SCHEDULED</td><td>The offer exists but the pickup window has not started yet</td></tr>
<tr><td>Red</td><td>SOLD OUT / CANCELLED</td><td>No more orders possible — sold out is temporary, cancelled is permanent</td></tr>
<tr><td>Yellow</td><td>EXPIRED</td><td>The pickup window ended — the offer is no longer available</td></tr>
<tr><td>Grey</td><td>HIDDEN / INACTIVE</td><td>The business manually disabled it — can be re-enabled any time</td></tr>
</table>

<h2>Real Example — "Morning Pastry Bag" at a Bakery</h2>
<p>
Mario the baker creates a "Morning Pastry Bag" offer at <strong>7:00 AM</strong>
with <code>quantityAvailable = 5</code>, <code>startTime = 09:00</code>, <code>endTime = 10:30</code>.
Here is what happens step by step:
</p>
<ol>
  <li><strong>07:00</strong> — Mario creates the offer → status = <strong>SCHEDULED</strong>
      (pickup window starts at 09:00, so customers cannot order yet)</li>
  <li><strong>09:00</strong> — Clock reaches startTime → status automatically becomes <strong>ACTIVE</strong>
      (the system computes this at runtime, nothing is written to the database)</li>
  <li><strong>09:10</strong> — Maria orders 2 bags → <code>quantityAvailable</code> drops to 3</li>
  <li><strong>09:30</strong> — Two more customers each order 1 bag → <code>quantityAvailable</code> = 1</li>
  <li><strong>09:45</strong> — Last customer orders the final bag → <code>quantityAvailable</code> = 0
      → status = <strong>SOLD OUT</strong></li>
  <li><strong>09:50</strong> — Maria cancels her order → 2 bags restored → <code>quantityAvailable</code> = 2
      → status automatically goes back to <strong>ACTIVE</strong> (dashed arrow in diagram)</li>
  <li><strong>10:30</strong> — endTime passes → status = <strong>EXPIRED</strong>
      (no more orders accepted regardless of remaining quantity)</li>
</ol>

{callout("info", "<strong>How does the status stay correct without constant DB updates?</strong> The status column in the database stores the raw value ('active'). When any client asks for the offer, the server runs a quick check at that moment: if quantityAvailable = 0 → return 'sold_out'; if now > endTime → return 'expired'; otherwise return what's stored. This means the status is always accurate without needing a background job.")}

<h2>What the Business Can Control Manually</h2>
<table>
<tr><th>Action</th><th>Result</th><th>Reversible?</th></tr>
<tr><td>Hide offer</td><td>Status = HIDDEN — disappears from customer app immediately</td><td>Yes — business can un-hide it any time</td></tr>
<tr><td>Set inactive</td><td>Status = INACTIVE — same as hidden but signals "not planned to reactivate soon"</td><td>Yes</td></tr>
<tr><td>Cancel offer</td><td>Status = CANCELLED — permanently stopped, cannot be undone</td><td>No — this is a final state</td></tr>
</table>

<h2>Overselling Prevention</h2>
<p>Two safety nets prevent selling more bags than available:</p>
<ol>
  <li><strong>Application check</strong> — before saving any order, the server reads the current
      <code>quantityAvailable</code> from the database and rejects the request if it is less than the
      quantity ordered. Example: if only 1 bag is left and a customer tries to order 3, the server
      responds with "Not enough stock" and the order is not created.</li>
  <li><strong>Optimistic lock</strong> — imagine two customers both tap "Order" on the very last bag
      at exactly the same millisecond. Both requests pass the application check simultaneously.
      But the <code>version</code> column on the food_offer row means only the first one to save
      succeeds. The second request sees that the version has already changed and is rejected automatically.
      No extra work needed from the developer.</li>
</ol>
"""))

# ── 7. Order Lifecycle ──────────────────────────────────────────────────────
sections_html.append(section("7", "Order Lifecycle", "How an order moves from placement to delivery or cancellation", f"""
{img(svgs["order_lifecycle"], "Order Status Flow — solid arrows = normal progression; dashed arrows = undo or alternative paths; dotted lines = which business app tab the order appears in")}

<h2>How to Read This Diagram</h2>
<p>
Each <strong>box</strong> is a status the order can be in.
<strong>Solid arrows</strong> are the normal path forward — what happens in a successful delivery.
<strong>Dashed arrows</strong> are backwards or alternative paths — undo actions or cancellations.
The <strong>dotted lines</strong> on the right connect each status to the tab where it appears
in the Business Partner app (NEW, ACTIVE, or DONE).
</p>

<h2>Color Legend</h2>
<table>
<tr><th>Color</th><th>Status</th><th>Where it appears in the Business app</th></tr>
<tr><td>Yellow</td><td>PENDING — waiting for business decision</td><td>NEW tab — business must accept or reject</td></tr>
<tr><td>Light green</td><td>CONFIRMED — business accepted, food being prepared</td><td>ACTIVE tab</td></tr>
<tr><td>Medium green</td><td>READY FOR PICKUP — food is packed and ready</td><td>ACTIVE tab</td></tr>
<tr><td>Dark green</td><td>COMPLETED — order handed over, done</td><td>DONE tab</td></tr>
<tr><td>Red</td><td>CANCELLED — rejected or cancelled at any stage</td><td>DONE tab</td></tr>
</table>

<h2>Real Example — Maria Orders a Sushi Bag from Mario's Bistro</h2>
<ol>
  <li><strong>Maria places the order</strong> → a new Order row is created in the database with
      <code>status = pending</code>. The order appears instantly in Mario's <strong>NEW tab</strong>.
      Mario's phone buzzes with a push notification: "New order arrived!"</li>
  <li><strong>Mario taps Accept</strong> → status changes to <code>confirmed</code>.
      The order card <em>immediately</em> disappears from the NEW tab and appears in the
      <strong>ACTIVE tab</strong> — without any page refresh. (This is the optimistic update:
      the app moves the card instantly, then syncs with the server in the background.)</li>
  <li><strong>Mario finishes packing</strong> and taps "Mark Ready" → status changes to
      <code>ready_for_pickup</code>. Still in the ACTIVE tab. Mario can see an estimated delivery time.</li>
  <li><strong>The order is delivered</strong> → Mario taps "Complete" → status changes to
      <code>completed</code>. The card moves to the <strong>DONE tab</strong>. Stock is not restored
      (the order was fulfilled).</li>
</ol>

<h2>Alternative Path — Mario Rejects the Order</h2>
<ol>
  <li>Instead of Accept, Mario taps <strong>Reject</strong></li>
  <li>Status immediately changes to <code>cancelled</code></li>
  <li>The order moves directly to the <strong>DONE tab</strong></li>
  <li>The stock that was reserved (e.g. 1 Sushi Bag) is <strong>restored</strong> —
      quantityAvailable goes back up by 1, so another customer can order it</li>
  <li>Maria sees her order status update to "Cancelled" in her order history</li>
</ol>

{callout("warning", "<strong>Rules enforced by the server:</strong> You cannot skip steps. Trying to jump from PENDING directly to COMPLETED returns an error. You also cannot undo a COMPLETED or CANCELLED order — those are final states. The business can step backwards (e.g. READY → CONFIRMED if they need more time) but cannot go back to PENDING once accepted.")}

<hr/>

<h2>Order Placement — What the Server Does Behind the Scenes</h2>
{img(svgs["order_placement"], "Order Placement — 6 server-side steps run automatically every time a customer places an order")}

<h2>How to Read This Diagram</h2>
<p>
This diagram shows what happens <em>on the server</em> in the fraction of a second between
the customer tapping "Confirm Order" and the order appearing in the business partner's NEW tab.
The customer sees only a loading spinner. The server silently runs all 6 steps.
</p>

<h2>Step-by-Step with Real Numbers</h2>
<p>Maria orders <strong>2 Sushi Bags at €5.99 each</strong> from Mario's Bistro (delivery fee €2.50):</p>
<ol>
  <li>
    <strong>Step 1 — Validate Stock</strong><br>
    Server reads the Sushi Bag row from MySQL: <code>quantityAvailable = 3</code>.
    Maria wants 2. 3 &gt;= 2, so stock is OK.
    Server immediately decrements: <code>quantityAvailable = 1</code>.
    It also <em>reads the price from the database</em> (€5.99) — it never trusts the price
    the app sent, to prevent tampering.
    <br>If stock were 1 and Maria tried to order 2, the server would stop here and return an error:
    "Not enough stock available".
  </li>
  <li>
    <strong>Step 2 — Calculate Subtotal (server-side)</strong><br>
    2 bags × €5.99 = <strong>€11.98 subtotal</strong>. This calculation happens on the server —
    the app cannot send a fake lower amount.
  </li>
  <li>
    <strong>Step 3 — Snapshot the Delivery Address</strong><br>
    Instead of storing a foreign key to the address table, the server saves a plain text copy:
    <code>"Karl-Marx-Str. 12, 12043 Berlin, Germany"</code>.
    This means if Maria deletes her saved address tomorrow, this order will still show
    the correct delivery address — just like a printed receipt.
  </li>
  <li>
    <strong>Step 4 — Estimate Delivery Time</strong><br>
    The server uses the business location (latitude/longitude of Mario's Bistro) and
    Maria's delivery address to calculate an estimated delivery time and saves it on the order.
  </li>
  <li>
    <strong>Step 5 — Save Everything to MySQL</strong><br>
    The complete Order record and all OrderItem records are saved in a single database transaction.
    Total price = subtotal + delivery fee = €11.98 + €2.50 = <strong>€14.48</strong>.
  </li>
  <li>
    <strong>Step 6 — Send Push Notification to Staff</strong><br>
    The server looks up all staff accounts of Mario's Bistro and their device tokens.
    It sends a push notification to every staff phone via Firebase FCM:
    "New order! Maria — 2 × Sushi Bag — €14.48".
    Mario's phone buzzes within seconds.
  </li>
</ol>

{callout("success", "<strong>Result:</strong> Maria's app shows 'Order placed! Waiting for confirmation.' Mario's phone buzzes. The order appears in Mario's NEW tab. Total time from Maria tapping 'Confirm' to Mario's phone buzzing: under 2 seconds.")}
"""))

# ── 8. Customer Dashboard ───────────────────────────────────────────────────
sections_html.append(section("8", "Customer Dashboard", "Screens and flows available to regular customers browsing and ordering food", f"""
{img(svgs["customer_journey"], "Customer Journey — each box is a screen; arrows show what action takes you to the next screen; the red path shows what happens when a restaurant is closed")}

<h2>How to Read This Diagram</h2>
<p>
Each <strong>box</strong> is one screen the customer sees.
<strong>Arrows</strong> show what button or action moves the customer to the next screen.
There is one <strong>red / blocked path</strong>: if the restaurant is closed when
the customer taps "Order Now", they hit a dead end (a dialog saying the restaurant is closed)
and cannot continue to checkout.
The <strong>green path</strong> is the happy path — a successful order from browsing to tracking.
</p>

<h2>Real Example — Maria Finds and Orders a Sushi Bag</h2>
<ol>
  <li>
    <strong>Home Screen</strong> — Maria opens the app.
    She sees a list of food offers. The app only shows offers that are:
    (a) currently active, (b) whose pickup window has not ended yet, and
    (c) from restaurants that are currently open (<code>isActive = true</code>).
    Offers from closed restaurants are automatically hidden — Maria never even
    knows they exist.
  </li>
  <li>
    <strong>Offer Detail</strong> — Maria taps the "Sushi Bag" card from Mario's Bistro.
    She sees the full description, photo, original price (€12.00), sale price (€5.99),
    how many bags are left (3), and the pickup window (18:00 – 20:00).
  </li>
  <li>
    <strong>Business Active Check</strong> — When Maria taps "Order Now", the app checks
    whether Mario's Bistro is currently marked as open.
    <ul>
      <li>If <strong>open</strong> → Maria proceeds to Checkout (green path)</li>
      <li>If <strong>closed</strong> → Maria sees a dialog: "Mario's Bistro is temporarily closed.
          Please try again later." She cannot order. (red path in diagram)</li>
    </ul>
  </li>
  <li>
    <strong>Checkout Screen</strong> — Maria selects how many bags she wants (e.g. 2),
    chooses her saved delivery address ("Karl-Marx-Str. 12, Berlin"),
    types a note ("no wasabi please"), and sees the price breakdown:
    <br>Subtotal: 2 × €5.99 = €11.98
    <br>Delivery fee: €2.50
    <br><strong>Total: €14.48</strong>
  </li>
  <li>
    <strong>Payment Screen</strong> — Maria confirms payment details and taps "Place Order".
    The app sends the order to the server (see Section 7 — Order Placement for what
    happens on the server side).
  </li>
  <li>
    <strong>Order Placed</strong> — Maria's screen shows "Order placed! Waiting for confirmation."
    The order appears in her "My Orders" tab with status: Pending.
  </li>
  <li>
    <strong>Track Order</strong> — Maria can see her order status update in real time:
    Pending → Confirmed → Ready for Pickup → Completed.
    When Mario accepts the order, Maria's screen updates automatically.
  </li>
</ol>

{callout("success", "<strong>What if she changes her mind?</strong> Until the business accepts the order (status = pending), Maria can cancel it. After the business accepts (status = confirmed), she can no longer cancel from the app — she would need to contact the restaurant directly.")}

<h2>Home Screen — Exactly What the App Loads</h2>
<p>
The app asks the server for offers with these automatic filters — the customer never sees or sets them:
</p>
<table>
<tr><th>Filter</th><th>What it does</th><th>Example</th></tr>
<tr><td>status = active</td><td>Only show currently active offers</td><td>Hides sold-out, expired, hidden offers</td></tr>
<tr><td>endTime after now</td><td>Only show offers whose pickup window is still open</td><td>Hides bags whose pickup window ended at 18:00 if it's now 18:30</td></tr>
<tr><td>businessPartner.isActive = true</td><td>Only show offers from open restaurants</td><td>Hides all offers from Mario's Bistro if Mario toggled "Closed" on his dashboard</td></tr>
</table>

<h2>Customer Navigation (Bottom Bar)</h2>
<table>
<tr><th>Tab</th><th>What the Customer Sees</th><th>Example Use</th></tr>
<tr><td>Home</td><td>All available food offers near you</td><td>Maria browses for tonight's dinner deal</td></tr>
<tr><td>My Orders</td><td>All past and current orders with live status</td><td>Maria checks if Mario accepted her order yet</td></tr>
<tr><td>Favorites</td><td>Offers Maria saved with the heart button</td><td>Maria's favourite bakery bag — one tap to re-order</td></tr>
<tr><td>Profile</td><td>Name, saved addresses, settings, logout</td><td>Maria adds a new delivery address for her office</td></tr>
</table>
"""))

# ── 9. Business Partner Dashboard ───────────────────────────────────────────
sections_html.append(section("9", "Business Partner Dashboard", "Screens and workflows for restaurant and shop owners managing their business", f"""
{img(svgs["business_dashboard"], "Business Partner Dashboard — login leads to the main dashboard; from there, the four main areas are Orders, Menu, Settings, and Analytics; Orders splits into three tabs: NEW, ACTIVE, DONE")}

<h2>How to Read This Diagram</h2>
<p>
Start from the top-left: "Business Login". After logging in, the business lands on the
<strong>Dashboard</strong> (the home screen). From the dashboard, four areas branch off.
The <strong>Orders</strong> branch is the most important for daily operation — it splits into
three tabs that match the order lifecycle from Section 7.
</p>

<h2>Real Example — Mario's Tuesday Morning</h2>
<p>
Mario opens his restaurant at 9:00 AM. Here is his full workflow on the Business Dashboard:
</p>

<h3>Step 1 — Open the restaurant (Dashboard)</h3>
<p>
Mario logs in and sees the main Dashboard. At the top there is an <strong>Open/Closed toggle</strong>.
He taps it to set his restaurant as "Open" (<code>isActive = true</code>).
The app updates instantly — no loading spinner. Behind the scenes, the server saves this change.
Now Mario's food offers appear on every customer's Home screen.
</p>
<p>
If Mario had left the toggle as "Closed", every customer who tapped "Order Now" on one of
his offers would see: "Mario's Bistro is temporarily closed" — and could not place an order.
</p>

<h3>Step 2 — Publish a Food Offer (Menu Screen)</h3>
<p>
Mario goes to the <strong>Menu</strong> tab and taps "Add New Offer". He fills in:
</p>
<table>
<tr><th>Field</th><th>What Mario types</th><th>What it controls</th></tr>
<tr><td>Title</td><td>Sushi Bag</td><td>What customers see on the offer card</td></tr>
<tr><td>Category</td><td>Japanese</td><td>Used for filtering on the customer home screen</td></tr>
<tr><td>Original price</td><td>€12.00</td><td>Shown as struck-through to show the discount</td></tr>
<tr><td>Sale price</td><td>€5.99</td><td>What the customer pays — saved as unitPrice in order_item at order time</td></tr>
<tr><td>Quantity</td><td>5</td><td>Sets quantityAvailable = 5; decrements with each order</td></tr>
<tr><td>Pickup window</td><td>18:00 – 20:00</td><td>startTime and endTime; offer shows as "expired" after 20:00</td></tr>
<tr><td>Photo</td><td>(uploads image)</td><td>Stored in the image table; shown to customers on the offer card</td></tr>
</table>
<p>
Mario taps "Publish". The offer is now visible to all customers on their Home screen
with status = <strong>ACTIVE</strong> (or SCHEDULED if startTime is in the future).
</p>

{callout("warning", "<strong>KYC gate:</strong> If Mario's account is still in kycStatus = 'pending' (not yet approved by an Admin), the 'Publish' button is disabled. Mario can create the offer and save it as a draft, but it will not appear to customers until the Admin approves his account.")}

<h3>Step 3 — Managing Incoming Orders (Orders Screen — NEW tab)</h3>
<p>
At 18:03, Mario's phone buzzes: "New order! Maria — 2 × Sushi Bag — €14.48".
He opens the app and sees the order card in the <strong>NEW tab</strong>.
</p>
<table>
<tr><th>Action</th><th>What happens</th><th>Where the order goes</th></tr>
<tr><td>Tap Accept</td><td>Status → confirmed. App moves the card <em>instantly</em> (optimistic update). Server saves the change.</td><td>Disappears from NEW → appears in ACTIVE tab</td></tr>
<tr><td>Tap Reject</td><td>Status → cancelled. Stock restored (2 Sushi Bags go back). App moves the card instantly.</td><td>Disappears from NEW → appears in DONE tab</td></tr>
</table>
{callout("info", "<strong>Optimistic update:</strong> When Mario taps Accept, the card moves to the ACTIVE tab immediately — he does not see a spinner or have to wait. The app assumes the server will succeed and moves the card right away. If the server call fails (e.g. no internet), the card snaps back to the NEW tab and Mario sees an error message.")}

<h3>Step 4 — Advancing the Order (Orders Screen — ACTIVE tab)</h3>
<p>
Mario accepted the order. Now it shows in the <strong>ACTIVE tab</strong> with status <em>confirmed</em>.
As he prepares the food:
</p>
<ol>
  <li>Food is packed → Mario taps <strong>"Mark Ready"</strong> → status = <code>ready_for_pickup</code> (still in ACTIVE tab)</li>
  <li>Order is delivered → Mario taps <strong>"Complete"</strong> → status = <code>completed</code> → card moves to <strong>DONE tab</strong></li>
</ol>
<p>
If Mario made a mistake (e.g. accepted an order he cannot fill), he can tap <strong>"Move Back"</strong>
to undo one step (e.g. from confirmed back to pending), or tap <strong>"Cancel"</strong> to cancel entirely.
</p>

<h3>Step 5 — End of Day (Orders Screen — DONE tab)</h3>
<p>
The DONE tab is view-only. It shows all completed and cancelled orders for the day.
Mario can see each order's total, the customer name, and the exact time it was completed or cancelled.
This is his daily order history — useful for reconciling with his earnings report.
</p>

<h2>Menu Management — Full Actions</h2>
<table>
<tr><th>Action</th><th>When to use it</th><th>Effect on customers</th></tr>
<tr><td>Publish new offer</td><td>New bag available today</td><td>Appears on customer Home screen immediately</td></tr>
<tr><td>Edit offer</td><td>Fix a typo or change quantity</td><td>Customers see the updated info</td></tr>
<tr><td>Hide offer</td><td>"Not ready yet, will re-enable in 30 min"</td><td>Disappears from customer Home screen; Mario can un-hide it any time</td></tr>
<tr><td>Set inactive</td><td>"Done for today, not planning to reactivate"</td><td>Same as hidden but signals a longer-term pause</td></tr>
<tr><td>Delete offer</td><td>Permanent removal</td><td>Cannot be undone; all linked images are also deleted</td></tr>
</table>

<h2>Team Members — Adding Staff</h2>
<p>
Mario can invite his colleague Luigi by email. Luigi gets an invitation, creates an account,
and is automatically assigned <code>ROLE_MEMBER</code>. Luigi's account is linked to Mario's Bistro.
When Luigi logs in, he sees the same Business Dashboard — including all orders.
However, Luigi cannot change banking details or business registration information.
</p>
<p>
Both Mario and Luigi receive push notifications when a new order arrives.
The server sends the notification to <em>all device tokens</em> linked to any staff member
of Mario's Bistro — so even if Mario's phone is off, Luigi's phone buzzes.
</p>
"""))

# ── 10. Admin Dashboard ─────────────────────────────────────────────────────
sections_html.append(section("10", "Admin Dashboard", "Platform-wide oversight — all businesses, customers, and orders in one place", f"""
<h2>What the Admin Sees</h2>
<p>The Admin bypasses all automatic query filters. Where a regular customer only sees their own orders, the Admin sees every order on the platform.</p>

<table>
<tr><th>Tab</th><th>Content</th><th>Key Actions</th></tr>
<tr><td>Overview</td><td>Total users, orders today, revenue, live order count</td><td>Platform health at a glance</td></tr>
<tr><td>Partners</td><td>All business partners</td><td>Approve / reject KYC, view business details</td></tr>
<tr><td>Customers</td><td>All customer accounts</td><td>View order history, contact info, account status</td></tr>
<tr><td>Orders</td><td>All orders platform-wide</td><td>Filter by status, date; see full order details</td></tr>
<tr><td>Offers</td><td>All food offers</td><td>See active, expired, sold-out offers across all businesses</td></tr>
</table>

{callout("info", "<strong>Why does Admin see everything?</strong> The Doctrine query extensions check the user's role before adding any filter. When ROLE_ADMIN is detected, no filter is added — the raw unfiltered query runs.")}

<h2>KYC Approval Workflow</h2>
<ol>
  <li>Business registers — kycStatus = 'pending'</li>
  <li>Admin sees the business in the Partners tab with a "Pending" badge</li>
  <li>Admin reviews registration details (business name, registration number, tax number)</li>
  <li>Admin taps Approve — PATCH /api/business_partners sets kycStatus = 'approved'</li>
  <li>Business can now create and publish food offers</li>
</ol>
"""))

# ── 11. Tech Stack ──────────────────────────────────────────────────────────
sections_html.append(section("11", "Tech Stack Reference", "Every technology used, why it was chosen, and how it fits in", f"""
<table>
<tr><th>Layer</th><th>Technology</th><th>Why Chosen</th></tr>
<tr><td>Mobile UI</td><td>Flutter (Dart)</td><td>Single codebase for iOS + Android; fast UI with native performance</td></tr>
<tr><td>State Management</td><td>GetX</td><td>Reactive state + dependency injection + routing in one package; minimal boilerplate</td></tr>
<tr><td>HTTP Client</td><td>Dio</td><td>Interceptors for automatic token injection and refresh</td></tr>
<tr><td>Secure Storage</td><td>FlutterSecureStorage</td><td>Uses iOS Keychain / Android Keystore — tokens stored encrypted</td></tr>
<tr><td>Auth Server</td><td>Keycloak</td><td>Open-source, self-hosted identity provider; manages passwords, JWT signing, roles</td></tr>
<tr><td>API Framework</td><td>Symfony + API Platform</td><td>Generates REST endpoints from PHP entities; built-in serialization groups, filters, pagination</td></tr>
<tr><td>ORM</td><td>Doctrine</td><td>Maps PHP classes to MySQL tables; handles migrations, transactions, and optimistic locks</td></tr>
<tr><td>Database</td><td>MySQL</td><td>Relational structure fits the data model; strong ACID guarantees for orders and stock</td></tr>
<tr><td>Infrastructure</td><td>Docker</td><td>Keycloak and MySQL each isolated in containers; easy local development and deployment</td></tr>
<tr><td>Push Notifications</td><td>Firebase FCM</td><td>Cross-platform (iOS + Android) push delivery</td></tr>
</table>

<h2>Flutter App Architecture (GetX Pattern)</h2>
<pre>Screen (View)         — displays UI only, zero business logic
      | reads .obs reactive values
      v
Controller            — holds state (.obs) + calls services
      | calls
      v
Service               — makes HTTP calls with Dio, parses JSON
      | returns
      v
Model (fromJson)      — plain Dart data class, no UI, no network</pre>

{callout("success", "<strong>Why this pattern?</strong> When a controller updates an .obs value, every Obx() widget that reads that value rebuilds automatically. No setState() needed. Controllers can be shared across multiple screens.")}

<h2>Full API Request Lifecycle</h2>
<pre>1.  User taps button in the UI
2.  Screen calls a method on the Controller
3.  Controller calls a Service method
4.  Service calls Dio to make an HTTP request
5.  AuthInterceptor runs:
       a. Reads stored access token
       b. If expired: calls Keycloak with refresh_token for a new token
       c. Attaches "Authorization: Bearer &lt;token&gt;" to the request
6.  HTTP request leaves the phone
7.  Symfony receives the request
8.  Keycloak JWT Guard validates the token signature + expiry
9.  KeycloakUserProvider looks up the User in MySQL by email
10. Doctrine query extensions add automatic WHERE clauses
    (e.g. "AND order.user_id = :current_user_id")
11. API Platform serializes the result using the active group
12. JSON response returns to Dio
13. Service parses JSON into a Model via fromJson()
14. Controller updates .obs reactive state
15. Obx() widgets on screen rebuild automatically
16. User sees the updated UI</pre>
"""))

# ─────────────────────────────────────────────────────────────────────────────
# ASSEMBLE FULL HTML
# ─────────────────────────────────────────────────────────────────────────────

toc_items = [
    ("1",  "Big Picture — System Architecture"),
    ("2",  "Authentication — Keycloak & JWT"),
    ("3",  "Registration & Login Flow"),
    ("4",  "Database Structure"),
    ("5",  "API Structure — Symfony / API Platform"),
    ("6",  "Food Offer Lifecycle"),
    ("7",  "Order Lifecycle"),
    ("8",  "Customer Dashboard"),
    ("9",  "Business Partner Dashboard"),
    ("10", "Admin Dashboard"),
    ("11", "Tech Stack Reference"),
]

toc_html = "".join(f"""
<div class="toc-item">
  <div class="toc-num">{n}</div>
  <span class="toc-title">{t}</span>
  <span class="toc-dots"></span>
</div>""" for n, t in toc_items)

full_html = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Foody App Documentation</title>
<style>{CSS}</style>
</head>
<body>

<!-- COVER -->
<div class="cover">
  <h1>Foody App</h1>
  <p class="cover-sub">System Documentation</p>
  <p class="cover-desc">
    Complete technical guide covering authentication, API structure,
    database design, order lifecycle, and all user dashboards.
  </p>
  <div>
    <span class="cover-badge">Flutter</span>
    <span class="cover-badge">Keycloak</span>
    <span class="cover-badge">Symfony</span>
    <span class="cover-badge">MySQL</span>
    <span class="cover-badge">Docker</span>
    <span class="cover-badge">Firebase FCM</span>
  </div>
  <div class="cover-meta">Version 1.0 &nbsp;&middot;&nbsp; July 2026</div>
</div>

<!-- TABLE OF CONTENTS -->
<div class="toc-page">
  <h2>Table of Contents</h2>
  {toc_html}
</div>

<!-- CONTENT -->
{"".join(sections_html)}

</body>
</html>"""

html_path = OUT_DIR / "_doc_full.html"
html_path.write_text(full_html)
print(f"HTML written: {html_path}  ({html_path.stat().st_size // 1024} KB)")

# ─────────────────────────────────────────────────────────────────────────────
# RENDER PDF via Chrome headless
# ─────────────────────────────────────────────────────────────────────────────

pdf_path = OUT_DIR / "DOCUMENTATION.pdf"
print("Rendering PDF with Chrome headless (this takes ~30 s)...")

chrome_cmd = [
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "--headless",                          # old headless mode — more stable
    "--disable-gpu",
    "--no-sandbox",
    "--disable-dev-shm-usage",
    "--allow-file-access-from-files",      # needed for local SVG src= references
    "--run-all-compositor-stages-before-draw",
    "--virtual-time-budget=10000",
    f"--print-to-pdf={pdf_path}",
    "--no-pdf-header-footer",
    f"file://{html_path}",
]

result = subprocess.run(chrome_cmd, capture_output=True, text=True, timeout=120)

if pdf_path.exists() and pdf_path.stat().st_size > 10_000:
    size_kb = pdf_path.stat().st_size // 1024
    print(f"PDF created: {pdf_path}  ({size_kb} KB)")
else:
    print("Chrome failed — trying chromium fallback...")
    print(result.stderr[-300:])

    # Fallback: use chromium via npx (puppeteer)
    node_script = OUT_DIR / "_pdf_render.js"
    node_script.write_text(f"""
const puppeteer = require('puppeteer');
(async () => {{
  const browser = await puppeteer.launch({{args: ['--no-sandbox', '--disable-dev-shm-usage']}});
  const page = await browser.newPage();
  await page.goto('file://{html_path}', {{waitUntil: 'networkidle0', timeout: 60000}});
  await page.pdf({{
    path: '{pdf_path}',
    format: 'A4',
    margin: {{top: '15mm', right: '15mm', bottom: '15mm', left: '15mm'}},
    printBackground: true,
  }});
  await browser.close();
  console.log('PDF written via puppeteer');
}})();
""")
    r2 = subprocess.run(["node", str(node_script)], capture_output=True, text=True,
                        cwd=str(OUT_DIR), timeout=90)
    print(r2.stdout or r2.stderr)
    if pdf_path.exists():
        print(f"PDF created via puppeteer: {pdf_path}  ({pdf_path.stat().st_size // 1024} KB)")
    else:
        print("Both engines failed. Open the HTML file in Chrome and File > Print > Save as PDF.")
        print(f"HTML is at: {html_path}")

print("Done.")
