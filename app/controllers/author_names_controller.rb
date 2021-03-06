class AuthorNamesController < ApplicationController
  before_filter :authenticate_editor

  def update
    author_name = AuthorName.find params[:id]
    author_name.name = params[:author_name]
    begin
      author_name.save!
    rescue ActiveRecord::RecordInvalid => invalid
      error = { error: "Name already exists" }
      render json: error, status: :conflict
      return
    end

    render_json author_name
  end

  def create
    author = Author.find params[:author_id]

    author_name = AuthorName.create author: author, name: params[:author_name]
    if author_name.errors.empty?
      author_name.touch_with_version
    end
    render_json author_name
  end

  # From URL: : "/authors/11282/author_names/194557"
  # Params are "author_id"(11282) and "id" (194557) (The latter links to author_names)

  def destroy
    author = Author.find params[:author_id]
    author_name = AuthorName.find params[:id]
    author_name.delete
    # Remove the author if there are no more author names that reference it
    unless AuthorName.find_by_author_id params[:author_id]
      author.delete
    end
    render json: nil
  end

  private
    def render_json author_name
      json = {
        content: render_to_string(partial: 'author_names/panel', locals: { author_name: author_name }),
        id: author_name.id,
        success: author_name.errors.empty?
      }

      render json: json
    end
end
