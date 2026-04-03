const STORAGE_KEY = "gym-attendance-marker-v2";
const MONTH_NAMES = [
  "January",
  "February",
  "March",
  "April",
  "May",
  "June",
  "July",
  "August",
  "September",
  "October",
  "November",
  "December",
];
const DAY_NAMES = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
const WORKOUT_OPTIONS = [
  "full-body",
  "chest",
  "biceps",
  "triceps",
  "back",
  "abs",
  "leg",
  "shoulder",
  "cardio",
];

const page = document.body.dataset.page;
let state = loadState();

if (page === "calendar") {
  initCalendarPage();
}

if (page === "dashboard") {
  initDashboardPage();
}

function loadState() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    const parsed = raw ? JSON.parse(raw) : null;

    if (parsed && parsed.years) {
      return {
        selectedYear: parsed.selectedYear || new Date().getFullYear(),
        selectedMonth: Number.isInteger(parsed.selectedMonth)
          ? parsed.selectedMonth
          : new Date().getMonth(),
        years: parsed.years,
      };
    }
  } catch (error) {
    console.warn("Unable to load saved tracker data.", error);
  }

  return {
    selectedYear: new Date().getFullYear(),
    selectedMonth: new Date().getMonth(),
    years: {},
  };
}

function saveState() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
}

function initCalendarPage() {
  const elements = {
    activeMonthLabel: document.querySelector("#activeMonthLabel"),
    prevMonthBtn: document.querySelector("#prevMonthBtn"),
    nextMonthBtn: document.querySelector("#nextMonthBtn"),
    todayBtn: document.querySelector("#todayBtn"),
    resetMonthBtn: document.querySelector("#resetMonthBtn"),
    calendarGrid: document.querySelector("#calendarGrid"),
    monthSummary: document.querySelector("#monthSummary"),
  };

  elements.prevMonthBtn.addEventListener("click", () => changeMonth(-1));
  elements.nextMonthBtn.addEventListener("click", () => changeMonth(1));

  elements.todayBtn.addEventListener("click", () => {
    const today = new Date();
    state.selectedYear = today.getFullYear();
    state.selectedMonth = today.getMonth();
    saveState();
    renderCalendarPage(elements);
  });

  elements.resetMonthBtn.addEventListener("click", () => {
    const monthName = MONTH_NAMES[state.selectedMonth];
    const confirmed = window.confirm(
      `Reset all entries for ${monthName} ${state.selectedYear}?`
    );

    if (!confirmed) {
      return;
    }

    const yearData = getYearData(state.selectedYear);
    Object.keys(yearData).forEach((dateKey) => {
      const [year, month] = dateKey.split("-").map(Number);
      if (year === state.selectedYear && month === state.selectedMonth + 1) {
        delete yearData[dateKey];
      }
    });
    saveState();
    renderCalendarPage(elements);
  });

  renderCalendarPage(elements);
}

function renderCalendarPage(elements) {
  const year = state.selectedYear;
  const monthIndex = state.selectedMonth;
  const monthLabel = `${MONTH_NAMES[monthIndex]} ${year}`;

  elements.activeMonthLabel.textContent = monthLabel;
  elements.calendarGrid.innerHTML = "";

  const firstDay = new Date(year, monthIndex, 1);
  const daysInMonth = new Date(year, monthIndex + 1, 0).getDate();
  const startOffset = toMondayIndex(firstDay.getDay());

  for (let i = 0; i < startOffset; i += 1) {
    const spacer = document.createElement("div");
    spacer.className = "calendar-spacer";
    elements.calendarGrid.appendChild(spacer);
  }

  for (let day = 1; day <= daysInMonth; day += 1) {
    elements.calendarGrid.appendChild(createDayCell(year, monthIndex, day));
  }

  const summary = computeMonthMetrics(year, monthIndex);
  elements.monthSummary.innerHTML = [
    summaryCard(
      "Attendance",
      `${summary.presentDays} present`,
      `${summary.absentDays} absent, ${summary.holidayDays} holidays, ${summary.sundayDays} Sundays`
    ),
    summaryCard(
      "Protein Avg / Day",
      `${summary.averageProteinPerLoggedDay} g`,
      `Across ${summary.proteinLoggedDays} logged day entries`
    ),
    summaryCard(
      "Protein Total",
      `${summary.totalProtein} g`,
      "Total manual protein entries for this month"
    ),
    summaryCard(
      "Attendance Rate",
      `${summary.attendanceRate}%`,
      "Present out of present plus absent days"
    ),
  ].join("");
}

function createDayCell(year, monthIndex, day) {
  const date = new Date(year, monthIndex, day);
  const dateKey = formatDateKey(year, monthIndex, day);
  const entry = getEntry(year, dateKey);
  const effectiveStatus = getEffectiveStatus(year, dateKey);
  const isToday = isSameDate(date, new Date());

  const cell = document.createElement("article");
  cell.className = `day-cell status-${effectiveStatus}${isToday ? " today" : ""}`;

  cell.innerHTML = `
    <div class="day-top">
      <div>
        <div class="day-number">${day}</div>
        <div class="day-name">${DAY_NAMES[toMondayIndex(date.getDay())]}</div>
      </div>
      <button class="status-toggle ${entry.status === "holiday" ? "active" : ""}" data-action="holiday" type="button">
        Holiday
      </button>
    </div>

    <div class="status-row">
      <button class="status-toggle ${entry.status === "present" ? "active" : ""}" data-status="present" type="button">
        Present
      </button>
      <button class="status-toggle ${entry.status === "absent" ? "active" : ""}" data-status="absent" type="button">
        Absent
      </button>
    </div>

    <div class="protein-wrap">
      <label for="protein-${dateKey}">Protein</label>
      <input
        id="protein-${dateKey}"
        class="protein-input"
        type="text"
        inputmode="text"
        placeholder="120g"
        value="${entry.proteinText || ""}"
      />
      <label for="workout-${dateKey}">Workout</label>
      <select id="workout-${dateKey}" class="workout-select">
        <option value="">Select workout</option>
        ${WORKOUT_OPTIONS.map(
          (option) => `
            <option value="${option}" ${entry.workoutType === option ? "selected" : ""}>
              ${formatWorkoutLabel(option)}
            </option>
          `
        ).join("")}
      </select>
    </div>

    <div class="status-note">${statusNote(effectiveStatus)}</div>
  `;

  cell.querySelectorAll("[data-status]").forEach((button) => {
    button.addEventListener("click", () => {
      const current = getEntry(year, dateKey);
      const nextStatus = current.status === button.dataset.status ? "unmarked" : button.dataset.status;
      setEntry(year, dateKey, {
        ...current,
        status: nextStatus,
      });
      refreshCurrentPage();
    });
  });

  cell.querySelector('[data-action="holiday"]').addEventListener("click", () => {
    const current = getEntry(year, dateKey);
    const nextStatus = current.status === "holiday" ? "unmarked" : "holiday";
    setEntry(year, dateKey, {
      ...current,
      status: nextStatus,
    });
    refreshCurrentPage();
  });

  cell.querySelector(".protein-input").addEventListener("change", (event) => {
    const current = getEntry(year, dateKey);
    setEntry(year, dateKey, {
      ...current,
      proteinText: sanitizeProteinText(event.target.value),
    });
    refreshCurrentPage();
  });

  cell.querySelector(".workout-select").addEventListener("change", (event) => {
    const current = getEntry(year, dateKey);
    setEntry(year, dateKey, {
      ...current,
      workoutType: event.target.value,
    });
    refreshCurrentPage();
  });

  return cell;
}

function initDashboardPage() {
  const elements = {
    yearSelect: document.querySelector("#yearSelect"),
    dashboardCards: document.querySelector("#dashboardCards"),
    consistencyStats: document.querySelector("#consistencyStats"),
    nutritionStats: document.querySelector("#nutritionStats"),
    bestMonthStats: document.querySelector("#bestMonthStats"),
    workoutSplitStats: document.querySelector("#workoutSplitStats"),
  };

  renderYearOptions(elements.yearSelect);

  elements.yearSelect.addEventListener("change", (event) => {
    state.selectedYear = Number(event.target.value);
    saveState();
    renderDashboardPage(elements);
  });

  renderDashboardPage(elements);
}

function renderDashboardPage(elements) {
  const year = state.selectedYear;
  const metrics = computeYearMetrics(year);

  renderYearOptions(elements.yearSelect);
  elements.yearSelect.value = String(year);

  elements.dashboardCards.innerHTML = [
    metricCard("Gym days", metrics.presentDays, "Total present days"),
    metricCard("Absent days", metrics.absentDays, "Total missed days"),
    metricCard("Holiday days", metrics.holidayDays, "Manual holidays marked"),
    metricCard("Sunday days", metrics.sundayDays, "Auto-counted Sundays"),
    metricCard("Protein avg", `${metrics.averageProteinPerLoggedDay} g`, "Average across logged entries"),
  ].join("");

  elements.consistencyStats.innerHTML = [
    detailRow("Attendance rate", `${metrics.attendanceRate}%`),
    detailRow("Tracked days", metrics.trackedDays),
    detailRow("Unmarked days", metrics.unmarkedDays),
    detailRow("Current streak", `${metrics.currentStreak} days`),
    detailRow("Best streak", `${metrics.longestStreak} days`),
  ].join("");

  elements.nutritionStats.innerHTML = [
    detailRow("Protein entries", metrics.proteinLoggedDays),
    detailRow("Total protein", `${metrics.totalProtein} g`),
    detailRow("Average per logged day", `${metrics.averageProteinPerLoggedDay} g`),
    detailRow("Average per month", `${metrics.averageProteinPerMonth} g`),
    detailRow("Best protein day", metrics.bestProteinDayLabel),
  ].join("");

  elements.bestMonthStats.innerHTML = [
    detailRow("Best attendance month", metrics.bestAttendanceMonth),
    detailRow("Lowest absence month", metrics.lowestAbsenceMonth),
    detailRow("Best protein month", metrics.bestProteinMonth),
    detailRow("Year selected", year),
  ].join("");

  elements.workoutSplitStats.innerHTML = WORKOUT_OPTIONS.map((option) =>
    detailRow(formatWorkoutLabel(option), metrics.workoutCounts[option] || 0)
  ).join("");
}

function changeMonth(step) {
  let month = state.selectedMonth + step;
  let year = state.selectedYear;

  if (month < 0) {
    month = 11;
    year -= 1;
  }

  if (month > 11) {
    month = 0;
    year += 1;
  }

  state.selectedMonth = month;
  state.selectedYear = year;
  saveState();
  refreshCurrentPage();
}

function refreshCurrentPage() {
  window.location.reload();
}

function renderYearOptions(select) {
  const currentYear = new Date().getFullYear();
  const years = Array.from(
    new Set([
      currentYear - 1,
      currentYear,
      currentYear + 1,
      ...Object.keys(state.years).map(Number),
    ])
  ).sort((a, b) => a - b);

  select.innerHTML = years
    .map((year) => `<option value="${year}">${year}</option>`)
    .join("");
}

function getYearData(year) {
  state.years[year] ||= {};
  return state.years[year];
}

function getEntry(year, dateKey) {
  return getYearData(year)[dateKey] || {
    status: "unmarked",
    proteinText: "",
    workoutType: "",
  };
}

function setEntry(year, dateKey, entry) {
  const cleanEntry = {
    status: entry.status || "unmarked",
    proteinText: sanitizeProteinText(entry.proteinText || ""),
    workoutType: sanitizeWorkoutType(entry.workoutType || ""),
  };

  if (
    cleanEntry.status === "unmarked" &&
    cleanEntry.proteinText === "" &&
    cleanEntry.workoutType === ""
  ) {
    delete getYearData(year)[dateKey];
  } else {
    getYearData(year)[dateKey] = cleanEntry;
  }

  saveState();
}

function getEffectiveStatus(year, dateKey) {
  const entry = getEntry(year, dateKey);

  if (entry.status !== "unmarked") {
    return entry.status;
  }

  const [entryYear, entryMonth, entryDay] = dateKey.split("-").map(Number);
  const weekday = new Date(entryYear, entryMonth - 1, entryDay).getDay();
  return weekday === 0 ? "sunday" : "unmarked";
}

function computeMonthMetrics(year, monthIndex) {
  const daysInMonth = new Date(year, monthIndex + 1, 0).getDate();
  let presentDays = 0;
  let absentDays = 0;
  let holidayDays = 0;
  let sundayDays = 0;
  let proteinLoggedDays = 0;
  let totalProtein = 0;
  const workoutCounts = createWorkoutCounts();

  for (let day = 1; day <= daysInMonth; day += 1) {
    const dateKey = formatDateKey(year, monthIndex, day);
    const entry = getEntry(year, dateKey);
    const status = getEffectiveStatus(year, dateKey);
    const proteinNumber = parseProtein(entry.proteinText);

    if (status === "present") presentDays += 1;
    if (status === "absent") absentDays += 1;
    if (status === "holiday") holidayDays += 1;
    if (status === "sunday") sundayDays += 1;

    if (proteinNumber !== null) {
      proteinLoggedDays += 1;
      totalProtein += proteinNumber;
    }

    if (status === "present" && entry.workoutType) {
      workoutCounts[entry.workoutType] += 1;
    }
  }

  const trackedDays = presentDays + absentDays;
  return {
    presentDays,
    absentDays,
    holidayDays,
    sundayDays,
    proteinLoggedDays,
    totalProtein,
    workoutCounts,
    trackedDays,
    attendanceRate: trackedDays === 0 ? 0 : round((presentDays / trackedDays) * 100),
    averageProteinPerLoggedDay:
      proteinLoggedDays === 0 ? 0 : round(totalProtein / proteinLoggedDays),
  };
}

function computeYearMetrics(year) {
  const monthMetrics = MONTH_NAMES.map((monthName, monthIndex) => ({
    monthName,
    ...computeMonthMetrics(year, monthIndex),
  }));

  const totalDaysInYear = isLeapYear(year) ? 366 : 365;
  const presentDays = sumBy(monthMetrics, "presentDays");
  const absentDays = sumBy(monthMetrics, "absentDays");
  const holidayDays = sumBy(monthMetrics, "holidayDays");
  const sundayDays = sumBy(monthMetrics, "sundayDays");
  const proteinLoggedDays = sumBy(monthMetrics, "proteinLoggedDays");
  const totalProtein = sumBy(monthMetrics, "totalProtein");
  const trackedDays = presentDays + absentDays;
  const unmarkedDays = totalDaysInYear - presentDays - absentDays - holidayDays - sundayDays;
  const workoutCounts = createWorkoutCounts();

  monthMetrics.forEach((month) => {
    WORKOUT_OPTIONS.forEach((option) => {
      workoutCounts[option] += month.workoutCounts[option] || 0;
    });
  });

  const bestAttendance = [...monthMetrics].sort((a, b) => b.presentDays - a.presentDays)[0];
  const lowestAbsence = [...monthMetrics].sort((a, b) => a.absentDays - b.absentDays)[0];
  const bestProtein = [...monthMetrics].sort((a, b) => b.totalProtein - a.totalProtein)[0];
  const streaks = calculateStreaks(year);

  return {
    presentDays,
    absentDays,
    holidayDays,
    sundayDays,
    trackedDays,
    unmarkedDays,
    proteinLoggedDays,
    totalProtein,
    attendanceRate: trackedDays === 0 ? 0 : round((presentDays / trackedDays) * 100),
    averageProteinPerLoggedDay:
      proteinLoggedDays === 0 ? 0 : round(totalProtein / proteinLoggedDays),
    averageProteinPerMonth: round(totalProtein / 12),
    workoutCounts,
    bestProteinDayLabel: findBestProteinDay(year),
    bestAttendanceMonth: `${bestAttendance.monthName} (${bestAttendance.presentDays} present)`,
    lowestAbsenceMonth: `${lowestAbsence.monthName} (${lowestAbsence.absentDays} absent)`,
    bestProteinMonth: `${bestProtein.monthName} (${bestProtein.totalProtein} g)`,
    currentStreak: streaks.current,
    longestStreak: streaks.longest,
  };
}

function calculateStreaks(year) {
  const totalDays = isLeapYear(year) ? 366 : 365;
  let longest = 0;
  let running = 0;

  for (let index = 0; index < totalDays; index += 1) {
    const date = new Date(year, 0, index + 1);
    const status = getEffectiveStatus(
      year,
      formatDateKey(year, date.getMonth(), date.getDate())
    );

    if (status === "present") {
      running += 1;
      longest = Math.max(longest, running);
    } else if (status === "absent" || status === "holiday" || status === "unmarked") {
      running = 0;
    }
  }

  let current = 0;
  for (let index = totalDays - 1; index >= 0; index -= 1) {
    const date = new Date(year, 0, index + 1);
    const status = getEffectiveStatus(
      year,
      formatDateKey(year, date.getMonth(), date.getDate())
    );

    if (status === "present") {
      current += 1;
      continue;
    }

    if (status === "sunday") {
      continue;
    }

    break;
  }

  return { current, longest };
}

function findBestProteinDay(year) {
  const entries = Object.entries(getYearData(year))
    .map(([dateKey, value]) => ({ dateKey, protein: parseProtein(value.proteinText) }))
    .filter((item) => item.protein !== null)
    .sort((a, b) => b.protein - a.protein);

  if (!entries.length) {
    return "No protein entries";
  }

  const top = entries[0];
  const [entryYear, entryMonth, entryDay] = top.dateKey.split("-").map(Number);
  const date = new Date(entryYear, entryMonth - 1, entryDay);
  return `${date.toLocaleDateString(undefined, { day: "numeric", month: "short" })} (${top.protein} g)`;
}

function metricCard(label, value, subtext) {
  return `
    <article class="metric-card">
      <p class="metric-label">${label}</p>
      <p class="metric-value">${value}</p>
      <p class="metric-subtext">${subtext}</p>
    </article>
  `;
}

function detailRow(label, value) {
  return `
    <div class="detail-row">
      <span>${label}</span>
      <strong>${value}</strong>
    </div>
  `;
}

function summaryCard(title, value, note) {
  return `
    <article class="summary-card">
      <h3>${title}</h3>
      <strong>${value}</strong>
      <small>${note}</small>
    </article>
  `;
}

function statusNote(status) {
  if (status === "present") return "Marked present";
  if (status === "absent") return "Marked absent";
  if (status === "holiday") return "Manual holiday";
  if (status === "sunday") return "Auto Sunday";
  return "Not marked yet";
}

function sanitizeProteinText(value) {
  return value.trim().slice(0, 12);
}

function sanitizeWorkoutType(value) {
  return WORKOUT_OPTIONS.includes(value) ? value : "";
}

function parseProtein(value) {
  if (!value) {
    return null;
  }

  const match = value.match(/(\d+(\.\d+)?)/);
  return match ? Number(match[1]) : null;
}

function formatDateKey(year, monthIndex, day) {
  return `${year}-${String(monthIndex + 1).padStart(2, "0")}-${String(day).padStart(2, "0")}`;
}

function toMondayIndex(jsDay) {
  return jsDay === 0 ? 6 : jsDay - 1;
}

function isLeapYear(year) {
  return new Date(year, 1, 29).getMonth() === 1;
}

function isSameDate(left, right) {
  return (
    left.getFullYear() === right.getFullYear() &&
    left.getMonth() === right.getMonth() &&
    left.getDate() === right.getDate()
  );
}

function round(value) {
  return Number.isFinite(value) ? Math.round(value * 10) / 10 : 0;
}

function sumBy(items, key) {
  return items.reduce((sum, item) => sum + item[key], 0);
}

function formatWorkoutLabel(value) {
  return value
    .split("-")
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(" ");
}

function createWorkoutCounts() {
  return WORKOUT_OPTIONS.reduce((counts, option) => {
    counts[option] = 0;
    return counts;
  }, {});
}
