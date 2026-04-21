import { useState, useMemo } from "react";

const FILTERS = ["All", "Active", "Completed"];
const PRIORITIES = ["Low", "Medium", "High"];

const PRIORITY_STYLES = {
  Low: { badge: "bg-blue-100 text-blue-700", dot: "bg-blue-400" },
  Medium: { badge: "bg-yellow-100 text-yellow-700", dot: "bg-yellow-400" },
  High: { badge: "bg-red-100 text-red-700", dot: "bg-red-500" },
};

let nextId = 4;

const initialTasks = [
  { id: 1, title: "Design system audit", priority: "High", completed: false, createdAt: Date.now() - 86400000 * 2 },
  { id: 2, title: "Write unit tests for auth module", priority: "Medium", completed: true, createdAt: Date.now() - 86400000 },
  { id: 3, title: "Update dependencies", priority: "Low", completed: false, createdAt: Date.now() },
];

function AddTaskForm({ onAdd }) {
  const [title, setTitle] = useState("");
  const [priority, setPriority] = useState("Medium");

  function handleSubmit(e) {
    e.preventDefault();
    const trimmed = title.trim();
    if (!trimmed) return;
    onAdd({ id: nextId++, title: trimmed, priority, completed: false, createdAt: Date.now() });
    setTitle("");
    setPriority("Medium");
  }

  return (
    <form onSubmit={handleSubmit} className="flex gap-2 mb-6">
      <input
        type="text"
        placeholder="New task…"
        value={title}
        onChange={(e) => setTitle(e.target.value)}
        className="flex-1 rounded-lg border border-gray-200 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-400"
      />
      <select
        value={priority}
        onChange={(e) => setPriority(e.target.value)}
        className="rounded-lg border border-gray-200 px-2 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-400"
      >
        {PRIORITIES.map((p) => (
          <option key={p}>{p}</option>
        ))}
      </select>
      <button
        type="submit"
        className="rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700 transition-colors"
      >
        Add
      </button>
    </form>
  );
}

function TaskRow({ task, onToggle, onDelete }) {
  const styles = PRIORITY_STYLES[task.priority];
  return (
    <li className="flex items-center gap-3 rounded-xl border border-gray-100 bg-white px-4 py-3 shadow-sm transition-opacity hover:shadow-md">
      <input
        type="checkbox"
        checked={task.completed}
        onChange={() => onToggle(task.id)}
        className="h-4 w-4 cursor-pointer accent-indigo-600"
      />
      <span
        className={`flex-1 text-sm ${task.completed ? "text-gray-400 line-through" : "text-gray-800"}`}
      >
        {task.title}
      </span>
      <span className={`inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-xs font-medium ${styles.badge}`}>
        <span className={`h-1.5 w-1.5 rounded-full ${styles.dot}`} />
        {task.priority}
      </span>
      <button
        onClick={() => onDelete(task.id)}
        aria-label="Delete task"
        className="ml-1 rounded p-1 text-gray-300 hover:bg-red-50 hover:text-red-400 transition-colors"
      >
        ✕
      </button>
    </li>
  );
}

function StatsBar({ tasks }) {
  const total = tasks.length;
  const done = tasks.filter((t) => t.completed).length;
  const pct = total === 0 ? 0 : Math.round((done / total) * 100);

  return (
    <div className="mb-6">
      <div className="flex justify-between text-xs text-gray-500 mb-1">
        <span>{done} of {total} tasks completed</span>
        <span>{pct}%</span>
      </div>
      <div className="h-2 w-full rounded-full bg-gray-100 overflow-hidden">
        <div
          className="h-full rounded-full bg-indigo-500 transition-all duration-300"
          style={{ width: `${pct}%` }}
        />
      </div>
    </div>
  );
}

export default function TaskManagerDashboard() {
  const [tasks, setTasks] = useState(initialTasks);
  const [filter, setFilter] = useState("All");
  const [search, setSearch] = useState("");

  const visible = useMemo(() => {
    return tasks
      .filter((t) => {
        if (filter === "Active") return !t.completed;
        if (filter === "Completed") return t.completed;
        return true;
      })
      .filter((t) => t.title.toLowerCase().includes(search.toLowerCase()))
      .sort((a, b) => b.createdAt - a.createdAt);
  }, [tasks, filter, search]);

  function addTask(task) {
    setTasks((prev) => [task, ...prev]);
  }

  function toggleTask(id) {
    setTasks((prev) => prev.map((t) => (t.id === id ? { ...t, completed: !t.completed } : t)));
  }

  function deleteTask(id) {
    setTasks((prev) => prev.filter((t) => t.id !== id));
  }

  function clearCompleted() {
    setTasks((prev) => prev.filter((t) => !t.completed));
  }

  const completedCount = tasks.filter((t) => t.completed).length;

  return (
    <div className="min-h-screen bg-gray-50 flex items-start justify-center pt-16 px-4">
      <div className="w-full max-w-lg">
        <header className="mb-8">
          <h1 className="text-2xl font-bold text-gray-900">Task Manager</h1>
          <p className="text-sm text-gray-500 mt-1">Stay on top of what matters</p>
        </header>

        <StatsBar tasks={tasks} />
        <AddTaskForm onAdd={addTask} />

        {/* Filter + search bar */}
        <div className="flex gap-2 mb-4">
          <div className="flex rounded-lg border border-gray-200 overflow-hidden text-sm">
            {FILTERS.map((f) => (
              <button
                key={f}
                onClick={() => setFilter(f)}
                className={`px-3 py-1.5 transition-colors ${
                  filter === f ? "bg-indigo-600 text-white" : "bg-white text-gray-600 hover:bg-gray-50"
                }`}
              >
                {f}
              </button>
            ))}
          </div>
          <input
            type="search"
            placeholder="Search…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="flex-1 rounded-lg border border-gray-200 px-3 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-400"
          />
        </div>

        {/* Task list */}
        {visible.length === 0 ? (
          <p className="py-12 text-center text-sm text-gray-400">
            {search ? "No tasks match your search." : "No tasks here — add one above!"}
          </p>
        ) : (
          <ul className="flex flex-col gap-2">
            {visible.map((task) => (
              <TaskRow key={task.id} task={task} onToggle={toggleTask} onDelete={deleteTask} />
            ))}
          </ul>
        )}

        {/* Footer */}
        {completedCount > 0 && (
          <div className="mt-4 flex justify-end">
            <button
              onClick={clearCompleted}
              className="text-xs text-gray-400 hover:text-red-400 transition-colors"
            >
              Clear {completedCount} completed
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
