User.destroy_all
TimeEntry.destroy_all

admin = User.create!(name: "Admin", email: "admin@example.com", password: "password", role: "admin")
mgr   = User.create!(name: "Manager", email: "manager@example.com", password: "password", role: "user_manager")
alice = User.create!(name: "Alice", email: "alice@example.com", password: "password", role: "regular")

require "date"
5.times do |i|
  TimeEntry.create!(
    user: alice,
    date: Date.today - i,
    distance_km: (3.0 + i),
    duration_seconds: 1200 + i*60
  )
end

puts "Seeded: admin/admin@example.com, manager/manager@example.com, alice/alice@example.com (password: password)"
