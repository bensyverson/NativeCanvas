
layers = [
  {
    name: "sky-gradient",
    render(ctx, params, scene) {
      const { width, height } = scene.viewport;
      const grad = ctx.createLinearGradient(0, 0, 0, height);
      grad.addColorStop(0, "#020510");
      grad.addColorStop(0.5, "#0a0e2a");
      grad.addColorStop(1, "#1a1040");
      ctx.fillStyle = grad;
      ctx.fillRect(0, 0, width, height);
    }
  },
  {
    name: "stars",
    render(ctx, params, scene) {
      const { width, height } = scene.viewport;
      const count = 320;
      for (let i = 0; i < count; i++) {
        const x = nc.random(i * 7.3 + 1) * width;
        const y = nc.random(i * 3.7 + 2) * height * 0.85;
        const size = nc.random(i * 1.9 + 3) * 1.6 + 0.3;
        const alpha = nc.random(i * 5.1 + 4) * 0.6 + 0.4;
        ctx.beginPath();
        ctx.arc(x, y, size, 0, Math.PI * 2);
        ctx.fillStyle = `rgba(255, 255, 255, ${alpha})`;
        ctx.fill();
      }
    }
  },
  {
    name: "bright-stars",
    render(ctx, params, scene) {
      const { width, height } = scene.viewport;
      // A handful of brighter stars with soft glow
      const stars = [
        { sx: 0.12, sy: 0.08, r: 2.5, color: "#cce0ff" },
        { sx: 0.45, sy: 0.05, r: 3.0, color: "#fff8e8" },
        { sx: 0.72, sy: 0.13, r: 2.2, color: "#ffd0d0" },
        { sx: 0.88, sy: 0.07, r: 2.8, color: "#cce0ff" },
        { sx: 0.31, sy: 0.19, r: 2.0, color: "#ffffff" },
        { sx: 0.60, sy: 0.22, r: 2.4, color: "#ffe8cc" },
        { sx: 0.20, sy: 0.32, r: 1.9, color: "#ffffff" },
        { sx: 0.80, sy: 0.28, r: 2.6, color: "#cce0ff" },
        { sx: 0.50, sy: 0.38, r: 2.1, color: "#ffffff" },
        { sx: 0.15, sy: 0.55, r: 1.8, color: "#ffd0d0" },
      ];
      stars.forEach(s => {
        const x = s.sx * width;
        const y = s.sy * height;
        // glow
        const glow = ctx.createRadialGradient(x, y, 0, x, y, s.r * 7);
        const rgb = nc.hexToRgb(s.color);
        glow.addColorStop(0, `rgba(${rgb.r},${rgb.g},${rgb.b},0.5)`);
        glow.addColorStop(1, `rgba(${rgb.r},${rgb.g},${rgb.b},0)`);
        ctx.beginPath();
        ctx.arc(x, y, s.r * 7, 0, Math.PI * 2);
        ctx.fillStyle = glow;
        ctx.fill();
        // core
        ctx.beginPath();
        ctx.arc(x, y, s.r, 0, Math.PI * 2);
        ctx.fillStyle = s.color;
        ctx.fill();
      });
    }
  },
  {
    name: "milky-way",
    render(ctx, params, scene) {
      const { width, height } = scene.viewport;
      // Soft diagonal band of nebulosity
      ctx.save();
      ctx.translate(width * 0.5, height * 0.35);
      ctx.rotate(nc.degToRad(-28));
      const band = ctx.createLinearGradient(-width * 0.6, -60, -width * 0.6, 60);
      band.addColorStop(0,   "rgba(100, 120, 200, 0)");
      band.addColorStop(0.3, "rgba(110, 130, 220, 0.07)");
      band.addColorStop(0.5, "rgba(130, 150, 240, 0.13)");
      band.addColorStop(0.7, "rgba(110, 130, 220, 0.07)");
      band.addColorStop(1,   "rgba(100, 120, 200, 0)");
      ctx.fillStyle = band;
      ctx.fillRect(-width * 0.6, -80, width * 1.2, 160);
      ctx.restore();
    }
  },
  {
    name: "orion-constellation",
    render(ctx, params, scene) {
      const { width, height } = scene.viewport;
      // Orion — simplified positions (normalized)
      const stars = {
        betelgeuse:  { x: 0.35, y: 0.26 },
        bellatrix:   { x: 0.55, y: 0.25 },
        mintaka:     { x: 0.41, y: 0.38 },
        alnilam:     { x: 0.47, y: 0.40 },
        alnitak:     { x: 0.53, y: 0.42 },
        saiph:       { x: 0.38, y: 0.55 },
        rigel:       { x: 0.58, y: 0.53 },
        meissa:      { x: 0.45, y: 0.16 },
      };
      const lines = [
        ["betelgeuse", "bellatrix"],
        ["betelgeuse", "mintaka"],
        ["bellatrix",  "mintaka"],
        ["mintaka",    "alnilam"],
        ["alnilam",    "alnitak"],
        ["mintaka",    "saiph"],
        ["alnitak",    "rigel"],
        ["saiph",      "rigel"],
        ["betelgeuse", "meissa"],
        ["bellatrix",  "meissa"],
      ];
      const toXY = s => ({ x: stars[s].x * width, y: stars[s].y * height });

      // Draw lines
      ctx.save();
      ctx.strokeStyle = "rgba(180, 210, 255, 0.25)";
      ctx.lineWidth = 0.8;
      lines.forEach(([a, b]) => {
        const p1 = toXY(a), p2 = toXY(b);
        ctx.beginPath();
        ctx.moveTo(p1.x, p1.y);
        ctx.lineTo(p2.x, p2.y);
        ctx.stroke();
      });

      // Draw star dots
      Object.entries(stars).forEach(([name, s]) => {
        const x = s.x * width, y = s.y * height;
        const isBright = ["betelgeuse","rigel","bellatrix","saiph"].includes(name);
        const r = isBright ? 2.5 : 1.6;
        const glow = ctx.createRadialGradient(x, y, 0, x, y, r * 6);
        glow.addColorStop(0, "rgba(200, 225, 255, 0.6)");
        glow.addColorStop(1, "rgba(200, 225, 255, 0)");
        ctx.beginPath();
        ctx.arc(x, y, r * 6, 0, Math.PI * 2);
        ctx.fillStyle = glow;
        ctx.fill();
        ctx.beginPath();
        ctx.arc(x, y, r, 0, Math.PI * 2);
        ctx.fillStyle = "#e8f0ff";
        ctx.fill();
      });
      ctx.restore();
    }
  },
  {
    name: "horizon-glow",
    render(ctx, params, scene) {
      const { width, height } = scene.viewport;
      const grad = ctx.createLinearGradient(0, height * 0.65, 0, height);
      grad.addColorStop(0, "rgba(10, 6, 30, 0)");
      grad.addColorStop(0.5, "rgba(18, 10, 45, 0.7)");
      grad.addColorStop(1, "rgba(25, 12, 55, 1)");
      ctx.fillStyle = grad;
      ctx.fillRect(0, height * 0.65, width, height * 0.35);

      // subtle light pollution on horizon
      const glow = ctx.createRadialGradient(width * 0.5, height, 0, width * 0.5, height, width * 0.6);
      glow.addColorStop(0, "rgba(60, 30, 10, 0.25)");
      glow.addColorStop(1, "rgba(60, 30, 10, 0)");
      ctx.fillStyle = glow;
      ctx.fillRect(0, height * 0.7, width, height * 0.3);
    }
  },
  {
    name: "silhouette",
    render(ctx, params, scene) {
      const { width, height } = scene.viewport;
      // Treeline silhouette
      ctx.save();
      ctx.fillStyle = "#05030f";
      ctx.beginPath();
      ctx.moveTo(0, height);

      const segments = 60;
      for (let i = 0; i <= segments; i++) {
        const t = i / segments;
        const x = t * width;
        // base horizon
        const base = height * 0.80;
        // rolling hills
        const hill = Math.sin(t * Math.PI * 1.8) * 18 + Math.sin(t * Math.PI * 3.7 + 1) * 10;
        // trees — spiky noise
        const treeHeight = (nc.random(i * 9.1 + 7) * 30 + 12) * (nc.random(i * 2.3 + 5) > 0.25 ? 1 : 0.3);
        const y = base - hill - treeHeight;
        ctx.lineTo(x, y);
      }
      ctx.lineTo(width, height);
      ctx.closePath();
      ctx.fill();
      ctx.restore();
    }
  },
  {
    name: "labels",
    render(ctx, params, scene) {
      const { width, height } = scene.viewport;
      // Constellation name
      ctx.save();
      ctx.font = `italic 11px "Georgia"`;
      ctx.fillStyle = "rgba(180, 210, 255, 0.45)";
      ctx.fillText("Orion", width * 0.62, height * 0.40);

      // Title
      const title = "The Night Sky";
      const titleSize = nc.fitText(title, width * 0.7, "Avenir", "bold");
      const cappedSize = Math.min(titleSize, 52);
      ctx.font = `bold ${cappedSize}px "Avenir"`;
      ctx.fillStyle = "rgba(230, 235, 255, 0.88)";
      ctx.textAlign = "center";
      ctx.fillText(title, width * 0.5, height * 0.91);

      // Subtitle
      ctx.font = `13px "Avenir"`;
      ctx.fillStyle = "rgba(180, 200, 255, 0.5)";
      ctx.fillText("Every star a different age. Some already gone.", width * 0.5, height * 0.91 + 24);

      ctx.restore();
    }
  }
];
