"""quotes: revisions, validity, kind, negotiation rounds

Additive. New NOT NULL columns on dealerquote carry server defaults so existing rows stay valid.

Revision ID: 0004
Revises: 0003
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
import sqlmodel


revision: str = '0004'
down_revision: Union[str, Sequence[str], None] = '0003'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    with op.batch_alter_table('dealerquote') as batch:
        batch.add_column(sa.Column('status_reason', sqlmodel.sql.sqltypes.AutoString(), nullable=True))
        batch.add_column(sa.Column('kind', sqlmodel.sql.sqltypes.AutoString(), nullable=False, server_default='IN_STOCK'))
        batch.add_column(sa.Column('revision', sa.Integer(), nullable=False, server_default='1'))
        batch.add_column(sa.Column('valid_until', sa.DateTime(), nullable=True))
        batch.add_column(sa.Column('delivery_days', sa.Integer(), nullable=True))
        batch.add_column(sa.Column('warranty_months', sa.Integer(), nullable=True))
        batch.add_column(sa.Column('accepted_at', sa.DateTime(), nullable=True))
        batch.add_column(sa.Column('updated_at', sa.DateTime(), nullable=True))
    op.create_table(
        'quoterevision',
        sa.Column('id', sa.Uuid(), nullable=False),
        sa.Column('quote_id', sa.Uuid(), nullable=False),
        sa.Column('revision', sa.Integer(), nullable=False),
        sa.Column('price', sa.Integer(), nullable=False),
        sa.Column('message', sqlmodel.sql.sqltypes.AutoString(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['quote_id'], ['dealerquote.id']),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_quoterevision_quote_id'), 'quoterevision', ['quote_id'])
    op.create_table(
        'quoteround',
        sa.Column('id', sa.Uuid(), nullable=False),
        sa.Column('quote_id', sa.Uuid(), nullable=False),
        sa.Column('round_no', sa.Integer(), nullable=False),
        sa.Column('by', sqlmodel.sql.sqltypes.AutoString(), nullable=False),
        sa.Column('price', sa.Integer(), nullable=False),
        sa.Column('note', sqlmodel.sql.sqltypes.AutoString(), nullable=True),
        sa.Column('status', sqlmodel.sql.sqltypes.AutoString(), nullable=False),
        sa.Column('valid_until', sa.DateTime(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['quote_id'], ['dealerquote.id']),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_quoteround_quote_id'), 'quoteround', ['quote_id'])


def downgrade() -> None:
    op.drop_table('quoteround')
    op.drop_table('quoterevision')
    with op.batch_alter_table('dealerquote') as batch:
        for col in ('updated_at', 'accepted_at', 'warranty_months', 'delivery_days', 'valid_until', 'revision', 'kind', 'status_reason'):
            batch.drop_column(col)
