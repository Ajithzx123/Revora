"""notifications: events (in-app feed), deliveries, device tokens, preferences

Additive: four new tables, nothing existing is touched.

Revision ID: 0005
Revises: 0004
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
import sqlmodel


revision: str = '0005'
down_revision: Union[str, Sequence[str], None] = '0004'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'notificationevent',
        sa.Column('id', sa.Uuid(), nullable=False),
        sa.Column('recipient_id', sa.Uuid(), nullable=False),
        sa.Column('type', sqlmodel.sql.sqltypes.AutoString(), nullable=False),
        sa.Column('category', sqlmodel.sql.sqltypes.AutoString(), nullable=False),
        sa.Column('title', sqlmodel.sql.sqltypes.AutoString(), nullable=False),
        sa.Column('body', sqlmodel.sql.sqltypes.AutoString(), nullable=False),
        sa.Column('entity_type', sqlmodel.sql.sqltypes.AutoString(), nullable=True),
        sa.Column('entity_id', sqlmodel.sql.sqltypes.AutoString(), nullable=True),
        sa.Column('critical', sa.Boolean(), nullable=False),
        sa.Column('dedupe_key', sqlmodel.sql.sqltypes.AutoString(), nullable=False),
        sa.Column('read_at', sa.DateTime(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['recipient_id'], ['user.id']),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_notificationevent_recipient_id'), 'notificationevent', ['recipient_id'])
    op.create_index(op.f('ix_notificationevent_type'), 'notificationevent', ['type'])
    op.create_index(op.f('ix_notificationevent_dedupe_key'), 'notificationevent', ['dedupe_key'], unique=True)
    op.create_index(op.f('ix_notificationevent_created_at'), 'notificationevent', ['created_at'])

    op.create_table(
        'notificationdelivery',
        sa.Column('id', sa.Uuid(), nullable=False),
        sa.Column('event_id', sa.Uuid(), nullable=False),
        sa.Column('channel', sqlmodel.sql.sqltypes.AutoString(), nullable=False),
        sa.Column('status', sqlmodel.sql.sqltypes.AutoString(), nullable=False),
        sa.Column('attempts', sa.Integer(), nullable=False),
        sa.Column('deliver_after', sa.DateTime(), nullable=False),
        sa.Column('last_error', sqlmodel.sql.sqltypes.AutoString(), nullable=True),
        sa.Column('sent_at', sa.DateTime(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['event_id'], ['notificationevent.id']),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_notificationdelivery_event_id'), 'notificationdelivery', ['event_id'])
    op.create_index(op.f('ix_notificationdelivery_status'), 'notificationdelivery', ['status'])

    op.create_table(
        'devicetoken',
        sa.Column('id', sa.Uuid(), nullable=False),
        sa.Column('user_id', sa.Uuid(), nullable=False),
        sa.Column('token', sqlmodel.sql.sqltypes.AutoString(), nullable=False),
        sa.Column('platform', sqlmodel.sql.sqltypes.AutoString(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('last_seen_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['user.id']),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_devicetoken_user_id'), 'devicetoken', ['user_id'])
    op.create_index(op.f('ix_devicetoken_token'), 'devicetoken', ['token'], unique=True)

    op.create_table(
        'notificationpreference',
        sa.Column('id', sa.Uuid(), nullable=False),
        sa.Column('user_id', sa.Uuid(), nullable=False),
        sa.Column('category', sqlmodel.sql.sqltypes.AutoString(), nullable=False),
        sa.Column('push_enabled', sa.Boolean(), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['user.id']),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('user_id', 'category', name='uq_notification_pref'),
    )
    op.create_index(op.f('ix_notificationpreference_user_id'), 'notificationpreference', ['user_id'])


def downgrade() -> None:
    op.drop_table('notificationpreference')
    op.drop_table('devicetoken')
    op.drop_table('notificationdelivery')
    op.drop_table('notificationevent')
