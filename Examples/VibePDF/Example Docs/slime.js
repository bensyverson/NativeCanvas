
const margin = 48;
const accentColor = "#f5a623";
const darkBg = "#1a1a2e";
const lightText = "#f0ece2";
const mutedText = "#a89f8c";
const slimeGreen = "#7bc67e";
const slimeDark = "#2d6a30";

layers = [
  {
    name: "background",
    render(ctx, params, scene) {
      const { width, height } = scene.viewport;
      // Dark gradient background
      const grad = ctx.createLinearGradient(0, 0, 0, height);
      grad.addColorStop(0, "#0f0f1a");
      grad.addColorStop(1, "#1a2e1a");
      ctx.fillStyle = grad;
      ctx.fillRect(0, 0, width, height);

      // Subtle slime mold network pattern
      ctx.save();
      ctx.strokeStyle = "rgba(123, 198, 126, 0.07)";
      ctx.lineWidth = 1;
      const seed = 42;
      // Draw vein-like lines across the background
      for (let i = 0; i < 18; i++) {
        const x0 = nc.random(seed + i * 7) * width;
        const y0 = nc.random(seed + i * 13) * height;
        const x1 = nc.random(seed + i * 17) * width;
        const y1 = nc.random(seed + i * 23) * height;
        const cx1 = nc.random(seed + i * 31) * width;
        const cy1 = nc.random(seed + i * 37) * height;
        ctx.beginPath();
        ctx.moveTo(x0, y0);
        ctx.quadraticCurveTo(cx1, cy1, x1, y1);
        ctx.stroke();
      }
      ctx.restore();
    }
  },
  {
    name: "hero_blob",
    render(ctx, params, scene) {
      const { width } = scene.viewport;
      const cx = width / 2;
      const cy = 148;
      const r = 72;

      // Glowing slime blob
      const glow = ctx.createRadialGradient(cx, cy, 0, cx, cy, r * 1.8);
      glow.addColorStop(0, "rgba(123, 198, 126, 0.25)");
      glow.addColorStop(1, "rgba(123, 198, 126, 0)");
      ctx.fillStyle = glow;
      ctx.beginPath();
      ctx.arc(cx, cy, r * 1.8, 0, Math.PI * 2);
      ctx.fill();

      // Blob body — organic amoeba shape using bezier curves
      ctx.save();
      ctx.translate(cx, cy);
      const blobGrad = ctx.createRadialGradient(-10, -15, 5, 0, 0, r);
      blobGrad.addColorStop(0, "#b8f0a0");
      blobGrad.addColorStop(0.5, "#7bc67e");
      blobGrad.addColorStop(1, "#3a8c3e");
      ctx.fillStyle = blobGrad;
      ctx.shadowColor = "rgba(100, 220, 100, 0.6)";
      ctx.shadowBlur = 24;
      ctx.beginPath();
      ctx.moveTo(0, -r);
      ctx.bezierCurveTo(r * 0.8, -r * 0.9, r * 1.1, -r * 0.1, r * 0.8, r * 0.5);
      ctx.bezierCurveTo(r * 0.5, r * 1.1, -r * 0.5, r * 1.0, -r * 0.9, r * 0.4);
      ctx.bezierCurveTo(-r * 1.2, -r * 0.1, -r * 0.7, -r * 0.9, 0, -r);
      ctx.fill();

      // Pseudopods (tendrils)
      ctx.shadowBlur = 8;
      ctx.fillStyle = "rgba(123, 198, 126, 0.7)";
      // tendril 1
      ctx.beginPath();
      ctx.moveTo(r * 0.6, r * 0.2);
      ctx.bezierCurveTo(r * 1.3, r * 0.6, r * 1.8, r * 0.2, r * 2.1, r * 0.5);
      ctx.bezierCurveTo(r * 1.7, r * 0.4, r * 1.2, r * 0.7, r * 0.8, r * 0.5);
      ctx.fill();
      // tendril 2
      ctx.beginPath();
      ctx.moveTo(-r * 0.5, r * 0.7);
      ctx.bezierCurveTo(-r * 1.2, r * 1.3, -r * 1.6, r * 1.0, -r * 1.9, r * 1.4);
      ctx.bezierCurveTo(-r * 1.5, r * 1.0, -r * 1.0, r * 1.2, -r * 0.7, r * 0.9);
      ctx.fill();

      ctx.restore();
    }
  },
  {
    name: "title",
    render(ctx, params, scene) {
      const { width } = scene.viewport;
      const cx = width / 2;

      // Eyebrow label
      ctx.font = `600 11px "Helvetica Neue", sans-serif`;
      ctx.fillStyle = slimeGreen;
      ctx.textAlign = "center";
      ctx.letterSpacing = "3px";
      ctx.fillText("BIOLOGY  ·  INTELLIGENCE  ·  MYSTERY", cx, 248);
      ctx.letterSpacing = "0px";

      // Main title
      const titleText = "The Secret Life";
      const titleSize = nc.fitText(titleText, width - margin * 2, "Georgia", "bold italic");
      const clampedSize = Math.min(titleSize, 54);
      ctx.font = `bold italic ${clampedSize}px "Georgia"`;
      ctx.fillStyle = lightText;
      ctx.textAlign = "center";
      ctx.fillText(titleText, cx, 300);

      // Subtitle
      const subText = "…of Slime Molds!";
      const subSize = nc.fitText(subText, width - margin * 2, "Georgia", "bold italic");
      const clampedSub = Math.min(subSize, 54);
      ctx.font = `bold italic ${clampedSub}px "Georgia"`;
      ctx.fillStyle = slimeGreen;
      ctx.fillText(subText, cx, 350);

      // Tagline
      ctx.font = `16px "Georgia"`;
      ctx.fillStyle = mutedText;
      ctx.fillText("No brain. No neurons. No problem.", cx, 380);
    }
  },
  {
    name: "divider",
    render(ctx, params, scene) {
      const { width } = scene.viewport;
      const cx = width / 2;
      const y = 398;

      ctx.strokeStyle = "rgba(123, 198, 126, 0.4)";
      ctx.lineWidth = 1;
      ctx.beginPath();
      ctx.moveTo(margin, y);
      ctx.lineTo(cx - 20, y);
      ctx.stroke();

      // Diamond
      ctx.fillStyle = slimeGreen;
      ctx.beginPath();
      ctx.moveTo(cx, y - 5);
      ctx.lineTo(cx + 7, y);
      ctx.lineTo(cx, y + 5);
      ctx.lineTo(cx - 7, y);
      ctx.closePath();
      ctx.fill();

      ctx.beginPath();
      ctx.moveTo(cx + 20, y);
      ctx.lineTo(width - margin, y);
      ctx.stroke();
    }
  },
  {
    name: "body_columns",
    render(ctx, params, scene) {
      const { width } = scene.viewport;
      const colGap = 20;
      const colWidth = (width - margin * 2 - colGap) / 2;
      const col1x = margin;
      const col2x = margin + colWidth + colGap;
      const startY = 416;
      const fontSize = 10;
      const lineHeight = fontSize * 1.55;
      const font = `${fontSize}px "Georgia"`;

      ctx.font = font;
      ctx.fillStyle = lightText;
      ctx.textAlign = "left";

      // Column 1 content
      const sections1 = [
        {
          heading: "What is a Slime Mold?",
          body: "Slime molds are not fungi, not plants, and not animals. They occupy their own kingdom — Mycetozoa — and exist as single-celled amoebae for most of their lives. When food runs scarce, thousands of individual cells aggregate into a single pulsing, crawling mass that behaves as a unified organism."
        },
        {
          heading: "Solving Mazes Without a Brain",
          body: "In a landmark 2000 experiment, researchers placed oat flakes at both ends of a maze and introduced Physarum polycephalum. Within hours, the organism had found the food and dissolved all branches except the shortest, most efficient path. It solved the maze."
        },
        {
          heading: "Redesigning Tokyo's Rail Network",
          body: "Scientists placed oat flakes on a map of Tokyo matching the locations of major cities. The slime mold's network — grown over 26 hours — nearly perfectly replicated the actual Tokyo rail system. Engineers spend decades on such designs. The slime mold did it overnight."
        }
      ];

      const sections2 = [
        {
          heading: "Memory Without a Mind",
          body: "Slime molds can \"remember\" where they have been. They leave behind a trail of dried slime that they later detect and avoid, allowing efficient exploration without backtracking. Some researchers argue this constitutes a primitive form of spatial memory — stored not in neurons, but in mucus."
        },
        {
          heading: "Anticipating the Future",
          body: "In a 2008 study, slime molds were exposed to periodic cold shocks at regular intervals. After training, the mold spontaneously slowed its growth just before the next expected shock — even when no shock came. It had learned the rhythm of its environment."
        },
        {
          heading: "What Does This Mean?",
          body: "Slime molds challenge our deepest assumptions about intelligence. If a brainless, nerveless blob can solve optimization problems, form memories, and predict the future — perhaps cognition is not a gift of neurons alone. Perhaps intelligence is a property of matter itself."
        }
      ];

      function drawSections(sections, x) {
        let y = startY;
        for (const sec of sections) {
          // Heading
          ctx.font = `bold ${fontSize + 0.5}px "Helvetica Neue", sans-serif`;
          ctx.fillStyle = accentColor;
          const headLines = nc.wrapText(sec.heading, colWidth, ctx.font);
          for (const line of headLines) {
            ctx.fillText(line, x, y);
            y += lineHeight * 0.9;
          }
          y += 2;

          // Body
          ctx.font = font;
          ctx.fillStyle = lightText;
          const bodyLines = nc.wrapText(sec.body, colWidth, ctx.font);
          for (const line of bodyLines) {
            ctx.fillText(line, x, y);
            y += lineHeight;
          }
          y += lineHeight * 0.65;
        }
      }

      drawSections(sections1, col1x);
      drawSections(sections2, col2x);
    }
  },
  {
    name: "footer",
    render(ctx, params, scene) {
      const { width, height } = scene.viewport;
      const y = height - 36;

      // Footer line
      ctx.strokeStyle = "rgba(123, 198, 126, 0.2)";
      ctx.lineWidth = 1;
      ctx.beginPath();
      ctx.moveTo(margin, y - 10);
      ctx.lineTo(width - margin, y - 10);
      ctx.stroke();

      ctx.font = `10px "Helvetica Neue", sans-serif`;
      ctx.fillStyle = "rgba(168, 159, 140, 0.6)";
      ctx.textAlign = "left";
      ctx.fillText("Physarum polycephalum  ·  Kingdom Mycetozoa", margin, y + 4);

      ctx.textAlign = "right";
      ctx.fillText("Intelligence beyond the brain", width - margin, y + 4);
    }
  }
];
