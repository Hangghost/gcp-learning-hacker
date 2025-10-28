# pglogical Extension Documentation

## Description
pglogical is a logical replication system implemented entirely as a PostgreSQL extension. It provides a highly efficient method of replicating data using a publish/subscribe model for selective replication, requiring no triggers or external programs.

## URL
https://github.com/2ndQuadrant/pglogical

## Category
tools

## Target Audience
- Database administrators
- PostgreSQL developers
- DevOps engineers working with PostgreSQL replication

## Prerequisites
- PostgreSQL database administration knowledge
- Understanding of logical replication concepts
- Linux system administration basics

## Related Labs
- GSP918: Create and Manage Cloud SQL for PostgreSQL Instances

## Notes
pglogical features:
- Selective replication using publication/subscription model
- Row-based logical replication
- Support for DDL replication
- Conflict resolution capabilities
- Integration with PostgreSQL's logical decoding
- Efficient for large database migrations
- Minimal performance impact on source database
