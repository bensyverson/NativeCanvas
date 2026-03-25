
layers = [
  {
    name: "background",
    render(ctx, params, scene) {
      const { width, height } = scene.viewport;
      // Deep forest gradient background
      const grad = ctx.createLinearGradient(0, 0, 0, height);
      grad.addColorStop(0, "#0d1f0f");
      grad.addColorStop(0.5, "#1a3320");
      grad.addColorStop(1, "#0a1208");
      ctx.fillStyle = grad;
      ctx.fillRect(0, 0, width, height);
    }
  },
  {
    name: "mycelium-network",
    render(ctx, params, scene) {
      const { width, height } = scene.viewport;
      // Draw organic mycelium-like lines across lower portion
      ctx.save();
      ctx.globalAlpha = 0.18;
      ctx.strokeStyle = "#a8d5a2";
      ctx.lineWidth = 0.8;

      const nodes = [];
      const seed = 42;
      for (let i = 0; i < 38; i++) {
        nodes.push({
          x: nc.random(seed + i * 7) * width,
          y: height * 0.48 + nc.random(seed + i * 13) * height * 0.52
        });
      }

      // Connect nodes that are close enough
      for (let i = 0; i < nodes.length; i++) {
        for (let j = i + 1; j < nodes.length; j++) {
          const dx = nodes[i].x - nodes[j].x;
          const dy = nodes[i].y - nodes[j].y;
          const dist = Math.sqrt(dx * dx + dy * dy);
          if (dist < 160) {
            ctx.beginPath();
            ctx.moveTo(nodes[i].x, nodes[i].y);
            // slight curve
            const mx = (nodes[i].x + nodes[j].x) / 2 + (nc.random(seed + i + j) - 0.5) * 40;
            const my = (nodes[i].y + nodes[j].y) / 2 + (nc.random(seed + i * j) - 0.5) * 40;
            ctx.quadraticCurveTo(mx, my, nodes[j].x, nodes[j].y);
            ctx.stroke();
          }
        }
      }

      // Draw node dots
      ctx.globalAlpha = 0.35;
      ctx.fillStyle = "#c8f0c0";
      for (let i = 0; i < nodes.length; i++) {
        const r = 1.5 + nc.random(seed + i * 3) * 2.5;
        ctx.beginPath();
        ctx.arc(nodes[i].x, nodes[i].y, r, 0, Math.PI * 2);
        ctx.fill();
      }

      ctx.restore();
    }
  },
  {
    name: "tree-silhouettes",
    render(ctx, params, scene) {
      const { width, height } = scene.viewport;

      function drawTree(x, baseY, trunkH, trunkW, canopyR, seed) {
        // trunk
        ctx.save();
        ctx.globalAlpha = 0.55;
        ctx.fillStyle = "#1a2e1a";
        ctx.fillRect(x - trunkW / 2, baseY - trunkH, trunkW, trunkH);

        // canopy layers
        ctx.globalAlpha = 0.38;
        ctx.fillStyle = "#1e3d1e";
        for (let layer = 0; layer < 3; layer++) {
          const ly = baseY - trunkH - layer * canopyR * 0.5;
          const lr = canopyR * (1 - layer * 0.22);
          ctx.beginPath();
          ctx.arc(x, ly, lr, 0, Math.PI * 2);
          ctx.fill();
        }
        ctx.restore();
      }

      const trees = [
        { x: 55,  baseY: height, trunkH: 130, trunkW: 14, canopyR: 52 },
        { x: 130, baseY: height, trunkH: 180, trunkW: 18, canopyR: 70 },
        { x: 220, baseY: height, trunkH: 145, trunkW: 12, canopyR: 48 },
        { x: 310, baseY: height, trunkH: 210, trunkW: 22, canopyR: 82 },
        { x: 400, baseY: height, trunkH: 160, trunkW: 15, canopyR: 58 },
        { x: 490, baseY: height, trunkH: 190, trunkW: 19, canopyR: 72 },
        { x: 570, baseY: height, trunkH: 135, trunkW: 13, canopyR: 50 },
      ];

      trees.forEach((t, i) => drawTree(t.x, t.baseY, t.trunkH, t.trunkW, t.canopyR, i));
    }
  },
  {
    name: "top-label",
    render(ctx, params, scene) {
      const { width } = scene.viewport;
      const margin = 42;
      ctx.font = `600 10px "Helvetica Neue", Arial, sans-serif`;
      ctx.fillStyle = "#7bc87a";
      ctx.globalAlpha = 0.9;
      ctx.letterSpacing = "3px";
      const label = "NATURE'S HIDDEN WORLD";
      const lw = nc.measureText(label, ctx.font).width;
      ctx.fillText(label, (width - lw) / 2, 52);
      ctx.globalAlpha = 1;

      // decorative line
      const lineW = 60;
      ctx.strokeStyle = "#7bc87a";
      ctx.lineWidth = 0.8;
      ctx.globalAlpha = 0.5;
      ctx.beginPath();
      ctx.moveTo((width - lw) / 2 - lineW - 12, 48);
      ctx.lineTo((width - lw) / 2 - 12, 48);
      ctx.stroke();
      ctx.beginPath();
      ctx.moveTo((width + lw) / 2 + 12, 48);
      ctx.lineTo((width + lw) / 2 + 12 + lineW, 48);
      ctx.stroke();
      ctx.globalAlpha = 1;
    }
  },
  {
    name: "headline",
    render(ctx, params, scene) {
      const { width } = scene.viewport;
      const margin = 48;
      const maxWidth = width - margin * 2;

      const line1 = "The Secret";
      const line2 = "Social Lives";
      const line3 = "…of Trees!";

      const size = 66;
      ctx.font = `italic bold ${size}px "Georgia", serif`;
      ctx.fillStyle = "#e8f5e3";
      ctx.shadowColor = "rgba(0,0,0,0.6)";
      ctx.shadowBlur = 18;

      const l1w = nc.measureText(line1, ctx.font).width;
      const l2w = nc.measureText(line2, ctx.font).width;
      const l3w = nc.measureText(line3, ctx.font).width;

      const startY = 68;
      const lineH = size * 1.12;

      ctx.fillText(line1, (width - l1w) / 2, startY + lineH);
      ctx.fillText(line2, (width - l2w) / 2, startY + lineH * 2);
      ctx.fillText(line3, (width - l3w) / 2, startY + lineH * 3);

      ctx.shadowBlur = 0;
    }
  },
  {
    name: "deck",
    render(ctx, params, scene) {
      const { width } = scene.viewport;
      const margin = 64;
      const maxWidth = width - margin * 2;
      const size = 15;
      const font = `${size}px "Helvetica Neue", Arial, sans-serif`;
      ctx.font = font;
      ctx.fillStyle = "#a8d8a0";
      ctx.globalAlpha = 0.92;

      const deck = "Beneath every forest floor lies an internet of fungi — a vast, living network through which trees whisper warnings, share food, and nurture their young.";
      const lines = nc.wrapText(deck, maxWidth, font);
      const lineH = size * 1.65;
      const startY = 350;

      lines.forEach((line, i) => {
        const lw = nc.measureText(line, font).width;
        ctx.fillText(line, (width - lw) / 2, startY + i * lineH);
      });

      ctx.globalAlpha = 1;
    }
  },
  {
    name: "divider",
    render(ctx, params, scene) {
      const { width } = scene.viewport;
      ctx.strokeStyle = "#4a8a48";
      ctx.lineWidth = 1;
      ctx.globalAlpha = 0.5;
      const y = 455;
      const lineW = 180;
      const cx = width / 2;

      ctx.beginPath();
      ctx.moveTo(cx - lineW, y);
      ctx.lineTo(cx + lineW, y);
      ctx.stroke();

      // center diamond
      ctx.fillStyle = "#7bc87a";
      ctx.globalAlpha = 0.7;
      ctx.save();
      ctx.translate(cx, y);
      ctx.rotate(Math.PI / 4);
      ctx.fillRect(-4, -4, 8, 8);
      ctx.restore();
      ctx.globalAlpha = 1;
    }
  },
  {
    name: "body-columns",
    render(ctx, params, scene) {
      const { width, height } = scene.viewport;
      const margin = 42;
      const colGap = 20;
      const colW = (width - margin * 2 - colGap) / 2;
      const startY = 476;
      const size = 11.5;
      const lineH = size * 1.7;
      const font = `${size}px "Georgia", serif`;
      ctx.font = font;
      ctx.fillStyle = "#c5e8bf";
      ctx.globalAlpha = 0.88;

      const col1text = "When a tree is attacked by insects, it releases chemical signals through its roots and into the mycelium — the thread-like fungal web that laces through the soil. Neighboring trees pick up these signals and begin producing defensive compounds before the insects even reach them. It is, in every meaningful sense, a conversation.";

      const col2text = "Mother trees — the oldest, largest in a forest — funnel sugars and nutrients to seedlings growing in their shade, giving them a fighting chance. When a mother tree is dying, she floods the network with a final pulse of carbon and wisdom, seeding the next generation. The forest does not forget its own.";

      const lines1 = nc.wrapText(col1text, colW, font);
      const lines2 = nc.wrapText(col2text, colW, font);

      const x1 = margin;
      const x2 = margin + colW + colGap;

      lines1.forEach((line, i) => {
        ctx.fillText(line, x1, startY + i * lineH);
      });

      lines2.forEach((line, i) => {
        ctx.fillText(line, x2, startY + i * lineH);
      });

      ctx.globalAlpha = 1;
    }
  },
  {
    name: "pull-quote",
    render(ctx, params, scene) {
      const { width } = scene.viewport;
      const margin = 48;
      const maxWidth = width - margin * 2;
      const size = 19;
      const font = `italic ${size}px "Georgia", serif`;
      ctx.font = font;

      const quote = "\"Trees are not solitary beings. They are social creatures, and the forest is their community.\"";
      const lines = nc.wrapText(quote, maxWidth - 60, font);
      const lineH = size * 1.5;
      const totalH = lines.length * lineH;
      const y = 660;

      // background pill
      ctx.fillStyle = "rgba(120, 200, 120, 0.08)";
      nc.roundRect(ctx, margin, y - 28, maxWidth, totalH + 36, 6);
      ctx.fill();

      // left accent bar
      ctx.fillStyle = "#7bc87a";
      ctx.globalAlpha = 0.7;
      ctx.fillRect(margin, y - 20, 3, totalH + 20);
      ctx.globalAlpha = 1;

      ctx.fillStyle = "#d4f0cc";
      lines.forEach((line, i) => {
        ctx.fillText(line, margin + 18, y + i * lineH);
      });
    }
  },
  {
    name: "footer",
    render(ctx, params, scene) {
      const { width, height } = scene.viewport;
      const font = `10px "Helvetica Neue", Arial, sans-serif`;
      ctx.font = font;
      ctx.fillStyle = "#5a8a58";
      ctx.globalAlpha = 0.7;
      const text = "THE WOOD WIDE WEB  ·  FOREST COMMUNICATION  ·  MYCORRHIZAL NETWORKS";
      const tw = nc.measureText(text, font).width;
      ctx.fillText(text, (width - tw) / 2, height - 22);
      ctx.globalAlpha = 1;
    }
  }
];
