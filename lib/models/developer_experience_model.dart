/// Model for a Developer's Real Experience story.
class DeveloperExperienceModel {
  final String id;
  final String title;
  final String
  categoryTag; // e.g. 'Behavioral', 'Failure Lesson', 'Architecture Trade-off'
  final String situation;
  final String task;
  final String action;
  final String result;
  final String keyTakeaway;

  const DeveloperExperienceModel({
    required this.id,
    required this.title,
    required this.categoryTag,
    required this.situation,
    required this.task,
    required this.action,
    required this.result,
    required this.keyTakeaway,
  });
}

const List<DeveloperExperienceModel> devExperiences = [
  DeveloperExperienceModel(
    id: 'dev_exp_1',
    title: 'When My Pipeline Silently Dropped 40% of Records',
    categoryTag: 'Failure Lesson',
    situation:
        'We had a production Spark pipeline ingesting clickstream data from 3 sources into a central data lake. The pipeline had been running for 6 months without issues.',
    task:
        'A downstream analyst flagged that their dashboard numbers looked "off" — revenue figures were 40% lower than expected for the past 2 weeks.',
    action:
        'I traced the issue back to a schema evolution in one upstream source that silently changed a nullable column to non-nullable. Our Spark job was dropping rows that failed schema validation without raising any alerts. I added explicit schema validation checks, dead-letter queues for failed records, and data volume anomaly alerts using row-count thresholds.',
    result:
        'Recovered 2 weeks of missing data by replaying from the raw S3 bucket. Implemented a data quality framework that now catches schema drift within 15 minutes of a pipeline run.',
    keyTakeaway:
        'Silent failures are the most dangerous. Always instrument your pipelines with row-count checks, schema validation alerts, and dead-letter queues. A pipeline that "runs successfully" but drops data is worse than one that fails loudly.',
  ),
  DeveloperExperienceModel(
    id: 'dev_exp_2',
    title: 'Choosing Between Lambda and Kappa Architecture',
    categoryTag: 'Architecture Trade-off',
    situation:
        'Our team was designing a real-time analytics platform for a fintech client. The client needed both historical batch reports (daily/weekly) and real-time fraud detection (sub-second latency).',
    task:
        'Decide between Lambda Architecture (separate batch + streaming layers) and Kappa Architecture (streaming-only, reprocess for batch) given a 6-month delivery timeline and a team of 4 engineers.',
    action:
        'I ran a spike comparing both approaches. Lambda gave us proven reliability for batch but doubled the codebase complexity — two separate processing paths for the same business logic. Kappa with Kafka + Flink was simpler to maintain but required careful offset management for historical reprocessing. Given our team size and timeline, I recommended Kappa with a 90-day retention window on Kafka topics.',
    result:
        'Delivered the platform in 5 months. The single codebase reduced bugs by ~60% compared to our previous Lambda implementation at another client. Reprocessing historical data took 4 hours for 90 days of data — acceptable for the client.',
    keyTakeaway:
        'Lambda Architecture sounds appealing on paper but doubles your maintenance burden. For most teams under 6 engineers, Kappa with sufficient Kafka retention is the pragmatic choice. Always factor in team size when making architecture decisions.',
  ),
  DeveloperExperienceModel(
    id: 'dev_exp_3',
    title: 'Bombing a System Design Interview at Meta',
    categoryTag: 'Behavioral',
    situation:
        'I was interviewing for a Senior Data Engineer role at Meta. The system design round asked me to design a real-time metrics aggregation system for 10 billion events per day.',
    task:
        'Design the system end-to-end in 45 minutes, covering ingestion, processing, storage, and serving layers.',
    action:
        'I jumped straight into the technical solution — Kafka for ingestion, Flink for processing, Druid for storage. I spent 35 minutes on the architecture diagram and only 10 minutes on trade-offs. The interviewer kept asking "why not X?" and I kept defending my choices without acknowledging valid alternatives. I failed to ask clarifying questions upfront about read/write patterns, consistency requirements, and latency SLAs.',
    result:
        'Did not pass the round. The feedback was: "Strong technical knowledge but didn\'t demonstrate structured thinking or trade-off analysis." I re-interviewed 6 months later, spent the first 10 minutes on requirements clarification, and passed.',
    keyTakeaway:
        'System design interviews are not about the "right" architecture — they\'re about demonstrating structured thinking. Always spend the first 10 minutes clarifying requirements, constraints, and scale. The interviewer wants to see HOW you think, not just WHAT you know.',
  ),
  DeveloperExperienceModel(
    id: 'dev_exp_4',
    title: 'The dbt Model That Brought Down Our Warehouse',
    categoryTag: 'Failure Lesson',
    situation:
        'We were migrating from a legacy SQL Server DWH to Snowflake using dbt. I was responsible for the core fact table models — 500M+ rows of transaction data.',
    task:
        'Migrate the largest fact table model to dbt incremental strategy without downtime.',
    action:
        'I configured the model as `incremental` with `unique_key` on transaction_id. During the first full-refresh run in production, the model ran a MERGE statement on 500M rows — which consumed all available Snowflake credits in 3 hours and caused other jobs to queue. I hadn\'t tested the full-refresh cost, only the incremental run cost. I immediately suspended the query, switched to a `delete+insert` strategy with date partitioning, and ran the migration in 50M-row batches.',
    result:
        'Completed the migration in 6 hours with controlled credit consumption. Added a pre-hook to log estimated row counts before any full-refresh runs.',
    keyTakeaway:
        'Always test your dbt incremental strategy\'s full-refresh cost in a non-production environment before deploying. MERGE on large tables is expensive. Use `delete+insert` with partitioning for fact tables over 100M rows.',
  ),
  DeveloperExperienceModel(
    id: 'dev_exp_5',
    title: 'Negotiating a 35% Salary Bump by Reframing My Value',
    categoryTag: 'Behavioral',
    situation:
        'After 2 years at a startup, I received an offer from a Series B company for a Data Engineering Lead role. Their initial offer was 15% above my current salary — below market rate for the role.',
    task:
        'Negotiate a better offer without losing the opportunity, while maintaining a positive relationship with the hiring team.',
    action:
        'Instead of countering with a number immediately, I asked for 48 hours to review. I researched market rates on Levels.fyi and LinkedIn Salary for similar roles in the same city. I then scheduled a call and reframed the conversation around the value I\'d bring: I had led a pipeline migration that saved \$200K/year in infrastructure costs and built a team of 3 engineers. I presented a specific counter-offer with data to back it up, and offered flexibility on start date in exchange for the salary adjustment.',
    result:
        'Received a revised offer 35% above my original salary — 18% above their initial offer. The hiring manager later told me my structured approach to the negotiation actually increased their confidence in my seniority.',
    keyTakeaway:
        'Salary negotiation is a data problem. Come with market data, quantify your past impact in dollar terms, and always counter in writing after a verbal discussion. Never negotiate against yourself by accepting the first offer.',
  ),
];
