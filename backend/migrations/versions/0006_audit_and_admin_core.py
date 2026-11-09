"""audit: actor role, reason, before/after; quote void cause

Additive: nullable columns and indexes only.

Revision ID: 0006
Revises: 0005
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
import sqlmodel


revision: str = '0006'
down_revision: Union[str, Sequence[str], None] = '0005'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    with op.batch_alter_table('auditevent') as batch:
        batch.add_column(sa.Column('actor_role', sqlmodel.sql.sqltypes.AutoString(), nullable=True))
        batch.add_column(sa.Column('reason', sqlmodel.sql.sqltypes.AutoString(), nullable=True))
        batch.add_column(sa.Column('before_json', sqlmodel.sql.sqltypes.AutoString(), nullable=True))
        batch.add_column(sa.Column('after_json', sqlmodel.sql.sqltypes.AutoString(), nullable=True))
    op.create_index(op.f('ix_auditevent_entity_type'), 'auditevent', ['entity_type'])
    op.create_index(op.f('ix_auditevent_entity_id'), 'auditevent', ['entity_id'])
    op.create_index(op.f('ix_auditevent_created_at'), 'auditevent', ['created_at'])
    with op.batch_alter_table('dealerquote') as batch:
        batch.add_column(sa.Column('void_cause', sqlmodel.sql.sqltypes.AutoString(), nullable=True))


def downgrade() -> None:
    with op.batch_alter_table('dealerquote') as batch:
        batch.drop_column('void_cause')
    op.drop_index(op.f('ix_auditevent_created_at'), table_name='auditevent')
    op.drop_index(op.f('ix_auditevent_entity_id'), table_name='auditevent')
    op.drop_index(op.f('ix_auditevent_entity_type'), table_name='auditevent')
    with op.batch_alter_table('auditevent') as batch:
        batch.drop_column('after_json')
        batch.drop_column('before_json')
        batch.drop_column('reason')
        batch.drop_column('actor_role')
