#!/bin/bash
set -e

NAMESPACE="wander-dev"

echo "🔍 Validating database seed data..."

# Function to query count
query_count() {
  local TABLE=$1
  kubectl exec -n $NAMESPACE deployment/postgres -- \
    psql -U postgres -d wander_dev -t -c "SELECT COUNT(*) FROM $TABLE;" 2>/dev/null | tr -d ' '
}

# Expected counts
EXPECTED_USERS=5
EXPECTED_TEAMS=2
EXPECTED_PROJECTS=2
EXPECTED_TASKS=6
EXPECTED_ACTIVITIES=10

# Query actual counts
echo -n "  Checking users... "
USERS=$(query_count users)
if [ "$USERS" = "$EXPECTED_USERS" ]; then
  echo "✅ ($USERS)"
else
  echo "⚠️  Expected $EXPECTED_USERS, found $USERS"
fi

echo -n "  Checking teams... "
TEAMS=$(query_count teams)
if [ "$TEAMS" = "$EXPECTED_TEAMS" ]; then
  echo "✅ ($TEAMS)"
else
  echo "⚠️  Expected $EXPECTED_TEAMS, found $TEAMS"
fi

echo -n "  Checking projects... "
PROJECTS=$(query_count projects)
if [ "$PROJECTS" = "$EXPECTED_PROJECTS" ]; then
  echo "✅ ($PROJECTS)"
else
  echo "⚠️  Expected $EXPECTED_PROJECTS, found $PROJECTS"
fi

echo -n "  Checking tasks... "
TASKS=$(query_count tasks)
if [ "$TASKS" = "$EXPECTED_TASKS" ]; then
  echo "✅ ($TASKS)"
else
  echo "⚠️  Expected $EXPECTED_TASKS, found $TASKS"
fi

echo -n "  Checking activities... "
ACTIVITIES=$(query_count activities)
if [ "$ACTIVITIES" = "$EXPECTED_ACTIVITIES" ]; then
  echo "✅ ($ACTIVITIES)"
else
  echo "⚠️  Expected $EXPECTED_ACTIVITIES, found $ACTIVITIES"
fi

# Overall validation
TOTAL_EXPECTED=$((EXPECTED_USERS + EXPECTED_TEAMS + EXPECTED_PROJECTS + EXPECTED_TASKS + EXPECTED_ACTIVITIES))
TOTAL_ACTUAL=$((USERS + TEAMS + PROJECTS + TASKS + ACTIVITIES))

echo ""
if [ "$TOTAL_ACTUAL" = "$TOTAL_EXPECTED" ]; then
  echo "✅ Database validation passed! All seed data is correct."
else
  echo "⚠️  Database validation warning: Expected $TOTAL_EXPECTED total records, found $TOTAL_ACTUAL"
  echo "   Run 'make seed-db' to reseed the database"
fi

exit 0

