"""Generate docs/img/architecture.svg and docs/img/stack.svg. Run via `make diagrams`."""
import sys
from html import escape

OUT = sys.argv[1]

TF = ("#E8F0FE", "#1A73E8", "")
EXT = ("#F1F3F4", "#80868B", ' stroke-dasharray="6 4"')
GH = ("#E6F4EA", "#188038", "")
CLIENT = ("#FFFFFF", "#202124", "")
FONT = "Helvetica, Arial, sans-serif"


def head(w, h, title):
    return [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}" font-family="{FONT}">',
        f"<title>{escape(title)}</title>",
        "<defs><marker id=\"a\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\">"
        "<path d=\"M0,0 L10,5 L0,10 z\" fill=\"#5F6368\"/></marker></defs>",
        f'<rect width="{w}" height="{h}" fill="#FFFFFF"/>',
    ]


def box(x, y, w, h, style, title, sub=None, lines=None):
    fill, stroke, dash = style
    o = [f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="8" fill="{fill}" stroke="{stroke}" stroke-width="1.5"{dash}/>']
    cx = x + w / 2
    if lines:
        o.append(f'<text x="{x + 14}" y="{y + 24}" font-size="15" font-weight="bold" fill="#202124">{escape(title)}</text>')
        for i, ln in enumerate(lines):
            o.append(f'<text x="{x + 14}" y="{y + 50 + i * 22}" font-size="13" fill="#3C4043" xml:space="preserve">{escape(ln)}</text>')
        return o
    subs = [sub] if isinstance(sub, str) else list(sub or [])
    ty = y + h / 2 + (-4 - 8 * (len(subs) - 1) if subs else 5)
    o.append(f'<text x="{cx}" y="{ty}" font-size="15" font-weight="bold" fill="#202124" text-anchor="middle">{escape(title)}</text>')
    for i, s in enumerate(subs):
        o.append(f'<text x="{cx}" y="{ty + 19 + i * 16}" font-size="12" fill="#5F6368" text-anchor="middle">{escape(s)}</text>')
    return o


def arrow(points, label=None, lx=None, ly=None):
    d = "M" + " L".join(f"{x},{y}" for x, y in points)
    o = [f'<path d="{d}" fill="none" stroke="#5F6368" stroke-width="1.5" marker-end="url(#a)"/>']
    if label:
        o.append(f'<text x="{lx}" y="{ly}" font-size="12" fill="#5F6368">{escape(label)}</text>')
    return o


def legend(x, y):
    o = []
    for i, (style, text) in enumerate([(TF, "Managed by Terraform"), (GH, "GitHub (CI, registry)"), (EXT, "Outside Terraform")]):
        fill, stroke, dash = style
        yy = y + i * 28
        o.append(f'<rect x="{x}" y="{yy}" width="26" height="18" rx="4" fill="{fill}" stroke="{stroke}" stroke-width="1.5"{dash}/>')
        o.append(f'<text x="{x + 36}" y="{yy + 14}" font-size="13" fill="#3C4043">{text}</text>')
    return o


def architecture():
    W, H = 1180, 870
    o = head(W, H, "Keycloak on Cloud Run: logical architecture")
    o.append(f'<text x="30" y="40" font-size="20" font-weight="bold" fill="#202124">Keycloak on Cloud Run</text>')
    o.append(f'<text x="30" y="62" font-size="13" fill="#5F6368">Request path and supporting services</text>')
    o += legend(30, 90)

    cx, cw = 340, 440  # centre column
    o += box(cx, 30, cw, 50, CLIENT, "Clients", "browsers, applications, kcadm.sh")
    o += box(cx, 120, cw, 56, EXT, "DNS A record: keycloak.example.com", "public zone, may live in another project")
    o += box(cx, 216, cw, 50, TF, "Global static IP", "shared by the :443 and :80 forwarding rules")
    o += box(cx, 306, cw, 66, TF, "Forwarding rule :443 → HTTPS proxy", "TLS terminated with an uploaded wildcard certificate")
    o += box(820, 306, 330, 66, TF, "Forwarding rule :80 → HTTP proxy", "301 redirect to https://")
    o += box(cx, 412, cw, 132, TF, "URL map (host: keycloak.example.com)", lines=[
        "/realms/  /.well-known/  /resources/  /js/   → backend",
        "/admin   → backend only with header",
        "             keycloak-kong: <secret value>",
        "anything else  → redirect away",
    ])
    o += box(cx, 584, 205, 50, TF, "Backend service", "external managed")
    o += box(cx + 235, 584, 205, 50, TF, "Serverless NEG", "→ Cloud Run service")
    o += box(cx, 674, cw, 70, TF, "Cloud Run: Keycloak 26", (
        "1 instance · start --optimized · ingress: internal + load balancer",
        "image pinned by digest · opt-in preview/experimental features"))
    o += box(cx, 784, 205, 56, TF, "Serverless VPC connector", "private ranges only")
    o += box(cx + 235, 784, 205, 56, TF, "Cloud SQL PostgreSQL 15", "private IP, no public IP")

    rx, rw = 820, 330
    o += box(rx, 412, rw, 56, GH, "GitHub Actions", "builds and signs the image")
    o += box(rx, 500, rw, 56, GH, "ghcr.io/bcollard/keycloak-cloudrun", "public, multi-arch, cosign-signed")
    o += box(rx, 588, rw, 56, TF, "Artifact Registry remote repo", "pull-through proxy of ghcr.io, serves the image")
    o += box(rx, 690, rw, 56, TF, "Secret Manager", "DB and bootstrap admin passwords, as env vars")

    mid = cx + cw / 2
    o += arrow([(mid, 80), (mid, 118)])
    o += arrow([(mid, 176), (mid, 214)])
    o += arrow([(mid, 266), (mid, 304)])
    o += arrow([(mid + 150, 266), (mid + 150, 286), (985, 286), (985, 304)])
    o += arrow([(mid, 372), (mid, 410)])
    o += arrow([(cx + 102, 544), (cx + 102, 582)])
    o += arrow([(cx + 205, 609), (cx + 233, 609)])
    o += arrow([(cx + 337, 634), (cx + 337, 672)])
    o += arrow([(cx + 102, 744), (cx + 102, 782)])
    o += arrow([(cx + 205, 812), (cx + 233, 812)])
    o += arrow([(985, 468), (985, 498)], "push", 993, 488)
    o += arrow([(985, 556), (985, 586)], "pull", 993, 576)
    o += arrow([(rx, 616), (800, 616), (800, 690), (cx + cw + 2, 690)])
    o += arrow([(rx, 718), (cx + cw + 2, 718)])
    o.append("</svg>")
    return "\n".join(o)


def stack():
    cols = [
        (TF, "Terraform (this repo)", [
            ("Edge", ["Global static IP", "Forwarding rules :443 and :80", "HTTPS proxy + uploaded certificate",
                      "HTTP proxy + redirect URL map", "URL map with path and header rules",
                      "Backend service + serverless NEG"]),
            ("Compute", ["Cloud Run service (Keycloak)", "Public invoker, ingress limited to GLB",
                         "Service account + IAM bindings"]),
            ("Data", ["Cloud SQL instance, database, user", "Serverless VPC Access connector"]),
            ("Supporting", ["Secret Manager secrets (2)", "Artifact Registry remote repo (ghcr.io)",
                            "Required project APIs"]),
        ]),
        (GH, "GitHub", [
            ("build-push.yml", ["Runs on KEYCLOAK_VERSION, Dockerfile,", "  server/** or workflow changes, or manually",
                                "Builds linux/amd64 + linux/arm64",
                                "Pushes to ghcr.io (public)", "Signs with cosign (keyless)"]),
            ("terraform-validate.yml", ["Runs on *.tf changes", "terraform init -backend=false + validate"]),
            ("Renovate", ["Bumps SHA-pinned actions", "  (uses Dependabot alerts for security PRs)"]),
        ]),
        (EXT, "Outside Terraform (one-time setup)", [
            ("GCP", ["GCS bucket for Terraform state", "Private services access on the VPC",
                     "  (needed by Cloud SQL private IP)"]),
            ("DNS and TLS", ["A record for the Keycloak hostname", "Wildcard cert via lego DNS-01",
                             "  (make server-cert)"]),
            ("Deploy", ["New image: set keycloak_image_digest", "  (make image-digest)",
                        "make tfa after each image or .tf change", "  (CI does not run terraform apply)"]),
            ("Keycloak", ["Realms, flows, passkeys: admin console", "  or kcadm.sh / Admin REST API"]),
        ]),
    ]
    W, cw, gap, x0 = 1180, 360, 25, 30
    rows = max(sum(len(items) + 1 for _, items in groups) for _, _, groups in cols)
    H = 120 + 60 + rows * 22 + 40
    o = head(W, H, "Keycloak on Cloud Run: what the stack includes")
    o.append(f'<text x="30" y="40" font-size="20" font-weight="bold" fill="#202124">What the stack includes</text>')
    o.append(f'<text x="30" y="62" font-size="13" fill="#5F6368">Who owns each piece, and what you set up once by hand</text>')
    top = 90
    for i, (style, title, groups) in enumerate(cols):
        x = x0 + i * (cw + gap)
        fill, stroke, dash = style
        o.append(f'<rect x="{x}" y="{top}" width="{cw}" height="{H - top - 30}" rx="10" fill="{fill}" stroke="{stroke}" stroke-width="1.5"{dash}/>')
        o.append(f'<text x="{x + 18}" y="{top + 32}" font-size="17" font-weight="bold" fill="{stroke}">{escape(title)}</text>')
        y = top + 66
        for gtitle, items in groups:
            o.append(f'<text x="{x + 18}" y="{y}" font-size="13" font-weight="bold" fill="#202124">{escape(gtitle)}</text>')
            y += 22
            for it in items:
                cont = it.startswith("  ")
                bullet = "" if cont else "• "
                o.append(f'<text x="{x + (40 if cont else 26)}" y="{y}" font-size="13" fill="#3C4043">{escape(bullet + it.strip())}</text>')
                y += 22
            y += 8
    o.append("</svg>")
    return "\n".join(o)


open(f"{OUT}/architecture.svg", "w").write(architecture())
open(f"{OUT}/stack.svg", "w").write(stack())
